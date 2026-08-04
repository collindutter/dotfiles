/**
 * Search Guard - blocks pathologically expensive recursive filesystem searches.
 *
 * Two classes of command are rejected before bash spawns them:
 *
 * 1. `grep -r` and `find`, which walk .gitignored directories. The agent is
 *    redirected to `rg` and `fd`, which honour ignore files.
 * 2. Any recursive search tool, including `rg` and `fd`, rooted at a "broad
 *    root": a filesystem location holding many independent checkouts. Broad
 *    roots come from a static list plus autodetection of workspace parents
 *    (directories whose children are themselves repositories).
 *
 * The motivating incident: an agent ran
 * `grep -rln "workflow_conflict" ~/Projects/griptape/`, which pinned a CPU
 * core for eighteen minutes traversing 911 node_modules directories spread
 * across 76 git repositories. Piping to `grep -v node_modules` filters the
 * output but does nothing to prevent the traversal.
 *
 * AGENTS.md permits falling back to grep/find when rg/fd lack a needed flag,
 * so every rejection names an explicit bypass: prefix the command with
 * `PI_ALLOW_BROAD_SEARCH=1`, or include a `# allow-broad-search` comment.
 *
 * Optional config at ~/.pi/agent/search-guard.json:
 *   { "extraBroadRoots": ["~/scratch"], "allowedRoots": ["~/Projects/mono"] }
 * `allowedRoots` overrides every other rule.
 *
 * This extension deliberately hooks the `tool_call` event rather than
 * registering its own bash tool. The sibling `uv.ts` extension owns the bash
 * tool via createBashTool; registering a second one would silently discard its
 * PATH shims.
 *
 * Known parser limitations: quote context is not restored after a command
 * substitution, `${...}` expansions render a path token unresolvable rather
 * than guessing at its value, and subshell nesting is not tracked, so a `cd`
 * inside `( ... )` leaks into later segments. The last case errs toward
 * blocking rather than allowing.
 */

import {
	isToolCallEventType,
	type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";
import { existsSync, readdirSync, readFileSync, realpathSync } from "node:fs";
import { homedir } from "node:os";
import { basename, join, resolve } from "node:path";

const HOME = homedir();

const BYPASS_PATTERN =
	/(?:^|\s)PI_ALLOW_BROAD_SEARCH=1(?:\s|$)|#\s*allow-broad-search/;

const GREP_FAMILY = new Set(["grep", "egrep", "fgrep", "ggrep", "ag", "ack"]);
const FIND_FAMILY = new Set(["find", "gfind"]);
const RG_FAMILY = new Set(["rg", "ripgrep"]);
const FD_FAMILY = new Set(["fd", "fdfind"]);

/** Every tool whose target path is subject to the broad-root rule. */
const SEARCH_COMMANDS = new Set([
	...GREP_FAMILY,
	...FIND_FAMILY,
	...RG_FAMILY,
	...FD_FAMILY,
	"rgrep",
]);

const STATIC_BROAD_ROOTS: readonly string[] = [
	"/",
	"/Users",
	"/Volumes",
	"/System",
	"/Library",
	"/Applications",
	"/usr",
	"/etc",
	"/var",
	"/private",
	"/opt",
	"/bin",
	"/sbin",
	"/tmp",
	HOME,
	join(HOME, "Library"),
	join(HOME, "Projects"),
	join(HOME, "Documents"),
	join(HOME, "Downloads"),
	join(HOME, "Desktop"),
	join(HOME, ".cache"),
	join(HOME, ".local"),
];

/** Directories examined per level when autodetecting workspace parents. */
const READDIR_CAP = 300;
const CHILD_SCAN_CAP = 50;

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

export interface GuardConfig {
	broadRoots: Set<string>;
	allowedRoots: string[];
}

function expandHome(input: string): string {
	if (input === "~") return HOME;
	if (input.startsWith("~/")) return join(HOME, input.slice(2));
	return input;
}

export function loadConfig(): GuardConfig {
	const broadRoots = new Set(STATIC_BROAD_ROOTS);
	const allowedRoots: string[] = [];

	try {
		const raw = readFileSync(join(HOME, ".pi", "agent", "search-guard.json"), "utf8");
		const parsed: unknown = JSON.parse(raw);
		if (parsed && typeof parsed === "object") {
			const { extraBroadRoots, allowedRoots: allowed } = parsed as {
				extraBroadRoots?: unknown;
				allowedRoots?: unknown;
			};
			if (Array.isArray(extraBroadRoots)) {
				for (const entry of extraBroadRoots) {
					if (typeof entry === "string") broadRoots.add(resolve(expandHome(entry)));
				}
			}
			if (Array.isArray(allowed)) {
				for (const entry of allowed) {
					if (typeof entry === "string") allowedRoots.push(resolve(expandHome(entry)));
				}
			}
		}
	} catch {
		// Missing or malformed config is not an error; fall back to defaults.
	}

	return { broadRoots, allowedRoots };
}

// ---------------------------------------------------------------------------
// Tokenizer
// ---------------------------------------------------------------------------

interface Word {
	kind: "word";
	value: string;
	/** Set when the token contains an expansion we cannot evaluate. */
	unresolvable: boolean;
}

interface Operator {
	kind: "op";
}

type Item = Word | Operator;

const OPERATOR_CHARS = new Set([";", "|", "&", "\n"]);

/**
 * Splits a shell command into words and segment separators.
 *
 * Command substitutions are treated as separators so that the commands inside
 * them are still inspected. Quote state is not restored afterwards, which can
 * over-segment exotic input but never under-segments it.
 */
function tokenize(command: string): Item[] {
	const items: Item[] = [];
	let value = "";
	let unresolvable = false;
	let started = false;

	const flush = (): void => {
		if (started) items.push({ kind: "word", value, unresolvable });
		value = "";
		unresolvable = false;
		started = false;
	};

	const pushOperator = (): void => {
		flush();
		const last = items[items.length - 1];
		if (last?.kind !== "op") items.push({ kind: "op" });
	};

	let i = 0;
	while (i < command.length) {
		const char = command[i];

		if (char === "'") {
			started = true;
			const end = command.indexOf("'", i + 1);
			if (end === -1) {
				value += command.slice(i + 1);
				break;
			}
			value += command.slice(i + 1, end);
			i = end + 1;
			continue;
		}

		if (char === '"') {
			started = true;
			i += 1;
			while (i < command.length && command[i] !== '"') {
				if (command[i] === "\\" && i + 1 < command.length) {
					value += command[i + 1];
					i += 2;
					continue;
				}
				if (command.startsWith("$(", i) || command[i] === "`") {
					unresolvable = true;
				}
				if (command.startsWith("${", i)) unresolvable = true;
				value += command[i];
				i += 1;
			}
			i += 1;
			continue;
		}

		if (char === "\\" && i + 1 < command.length) {
			started = true;
			value += command[i + 1];
			i += 2;
			continue;
		}

		// Command substitution and process substitution start a new segment.
		if (command.startsWith("$(", i) || command.startsWith("<(", i)) {
			pushOperator();
			i += 2;
			continue;
		}
		if (char === "`") {
			pushOperator();
			i += 1;
			continue;
		}

		if (command.startsWith("${", i)) {
			started = true;
			unresolvable = true;
			value += char;
			i += 1;
			continue;
		}

		if (char === "(" || char === ")") {
			pushOperator();
			i += 1;
			continue;
		}

		if (char !== undefined && OPERATOR_CHARS.has(char)) {
			pushOperator();
			i += 1;
			continue;
		}

		if (char === " " || char === "\t" || char === "\r") {
			flush();
			i += 1;
			continue;
		}

		started = true;
		value += char;
		i += 1;
	}

	flush();
	return items;
}

/** Groups tokenized words into command segments. */
function segments(command: string): Word[][] {
	const result: Word[][] = [];
	let current: Word[] = [];
	for (const item of tokenize(command)) {
		if (item.kind === "op") {
			if (current.length > 0) result.push(current);
			current = [];
			continue;
		}
		current.push(item);
	}
	if (current.length > 0) result.push(current);
	return result;
}

// ---------------------------------------------------------------------------
// Argument parsing
// ---------------------------------------------------------------------------

interface FlagSpec {
	/** Single-character flags that consume the following value. */
	short: Set<string>;
	/** Long flag names (without leading dashes) that consume a value. */
	long: Set<string>;
	/**
	 * Flags that supply the search pattern, which makes every positional
	 * argument a path. Empty for tools where these letters mean something else,
	 * such as fd's `-e` (extension).
	 */
	patternFlags: Set<string>;
	/** Flags after which the remainder of the segment is not a path. */
	terminators?: Set<string>;
	/** Long flags whose value is itself a search target. */
	pathValued?: Set<string>;
}

const GREP_FLAGS: FlagSpec = {
	short: new Set(["e", "f", "m", "A", "B", "C", "d", "D"]),
	long: new Set([
		"regexp",
		"file",
		"max-count",
		"after-context",
		"before-context",
		"context",
		"directories",
		"devices",
		"binary-files",
		"exclude",
		"exclude-dir",
		"exclude-from",
		"include",
		"label",
		"color",
		"colour",
	]),
	patternFlags: new Set(["e", "f", "regexp", "file"]),
};

const RG_FLAGS: FlagSpec = {
	short: new Set(["e", "f", "g", "t", "T", "m", "A", "B", "C", "M", "r", "j"]),
	long: new Set([
		"regexp",
		"file",
		"glob",
		"iglob",
		"type",
		"type-not",
		"max-count",
		"after-context",
		"before-context",
		"context",
		"max-depth",
		"max-columns",
		"colors",
		"color",
		"sort",
		"sortr",
		"pre",
		"replace",
		"ignore-file",
		"path-separator",
		"threads",
		"context-separator",
		"engine",
	]),
	patternFlags: new Set(["e", "f", "regexp", "file"]),
};

const FD_FLAGS: FlagSpec = {
	short: new Set(["d", "t", "e", "E", "c", "j", "S"]),
	long: new Set([
		"max-depth",
		"min-depth",
		"exact-depth",
		"type",
		"extension",
		"exclude",
		"ignore-file",
		"color",
		"threads",
		"size",
		"changed-within",
		"changed-before",
		"search-path",
		"base-directory",
		"path-separator",
		"format",
		"and",
	]),
	// fd takes its pattern positionally; -e is --extension, -f does not exist.
	patternFlags: new Set<string>(),
	terminators: new Set(["x", "exec", "X", "exec-batch"]),
	pathValued: new Set(["search-path", "base-directory"]),
};

interface ParsedSearch {
	/** Literal path arguments, before resolution. */
	paths: string[];
	/** The search pattern, when one could be identified. */
	pattern?: string;
	/** True when a recursive flag was supplied. */
	recursive: boolean;
	/** True when a token we could not evaluate may have been a path. */
	sawUnresolvable: boolean;
}

/** Parses grep-style and rg-style argv, where the pattern precedes paths. */
function parsePatternFirst(args: Word[], spec: FlagSpec): ParsedSearch {
	const paths: string[] = [];
	let pattern: string | undefined;
	let recursive = false;
	let patternFromFlag = false;
	let sawUnresolvable = false;
	let noMoreFlags = false;

	for (let i = 0; i < args.length; i += 1) {
		const arg = args[i];
		if (arg === undefined) continue;
		const token = arg.value;

		if (!noMoreFlags && token === "--") {
			noMoreFlags = true;
			continue;
		}

		if (!noMoreFlags && token.startsWith("--")) {
			const body = token.slice(2);
			const eq = body.indexOf("=");
			const name = eq === -1 ? body : body.slice(0, eq);
			if (name === "recursive" || name === "dereference-recursive") recursive = true;
			if (spec.patternFlags.has(name)) patternFromFlag = true;
			if (spec.terminators?.has(name)) break;
			if (spec.long.has(name) && eq === -1) {
				const next = args[i + 1];
				if (spec.pathValued?.has(name) && next !== undefined) {
					if (next.unresolvable) sawUnresolvable = true;
					else paths.push(next.value);
				}
				i += 1;
			}
			continue;
		}

		if (!noMoreFlags && token.startsWith("-") && token.length > 1) {
			const cluster = token.slice(1);
			for (let c = 0; c < cluster.length; c += 1) {
				const flag = cluster[c];
				if (flag === undefined) continue;
				if (flag === "r" || flag === "R") recursive = true;
				if (spec.patternFlags.has(flag)) patternFromFlag = true;
				if (spec.terminators?.has(flag)) return { paths, pattern, recursive, sawUnresolvable };
				if (spec.short.has(flag)) {
					// Remaining cluster characters are the value, else the next argv entry.
					if (c === cluster.length - 1) i += 1;
					break;
				}
			}
			continue;
		}

		if (arg.unresolvable) {
			sawUnresolvable = true;
			continue;
		}

		if (pattern === undefined && !patternFromFlag) {
			pattern = token;
			continue;
		}
		paths.push(token);
	}

	return { paths, pattern, recursive, sawUnresolvable };
}

/** Parses `find` argv, where paths precede the expression. */
function parseFind(args: Word[]): ParsedSearch {
	const paths: string[] = [];
	let sawUnresolvable = false;
	let i = 0;

	// BSD find accepts option clusters before the path list.
	while (i < args.length) {
		const arg = args[i];
		if (arg === undefined) break;
		if (/^-[HLPEXdsx]+$/.test(arg.value)) {
			i += 1;
			continue;
		}
		if (arg.value === "-f") {
			const next = args[i + 1];
			if (next !== undefined) {
				if (next.unresolvable) sawUnresolvable = true;
				else paths.push(next.value);
			}
			i += 2;
			continue;
		}
		break;
	}

	for (; i < args.length; i += 1) {
		const arg = args[i];
		if (arg === undefined) continue;
		const token = arg.value;
		if (token.startsWith("-") || token === "(" || token === ")" || token === "!" || token === ",") {
			break;
		}
		if (arg.unresolvable) {
			sawUnresolvable = true;
			continue;
		}
		paths.push(token);
	}

	return { paths, recursive: true, sawUnresolvable };
}

// ---------------------------------------------------------------------------
// Broad root detection
// ---------------------------------------------------------------------------

const repoLikeCache = new Map<string, number>();

/** Counts direct children that look like an independent checkout. */
function countRepoLike(dir: string): number {
	const cached = repoLikeCache.get(dir);
	if (cached !== undefined) return cached;

	let count = 0;
	try {
		const entries = readdirSync(dir, { withFileTypes: true });
		const limit = Math.min(entries.length, READDIR_CAP);
		for (let i = 0; i < limit; i += 1) {
			const entry = entries[i];
			if (entry === undefined || !entry.isDirectory()) continue;
			if (entry.name === "node_modules") {
				count += 1;
				continue;
			}
			if (existsSync(join(dir, entry.name, ".git"))) count += 1;
		}
	} catch {
		// Unreadable directories cannot be judged; treat as ordinary.
	}

	repoLikeCache.set(dir, count);
	return count;
}

function isWithin(child: string, parent: string): boolean {
	if (child === parent) return true;
	const prefix = parent.endsWith("/") ? parent : `${parent}/`;
	return child.startsWith(prefix);
}

function display(path: string): string {
	return path === HOME ? "~" : path.startsWith(`${HOME}/`) ? `~${path.slice(HOME.length)}` : path;
}

interface BroadVerdict {
	broad: boolean;
	reason: string;
}

function isBroadRoot(abs: string, config: GuardConfig): BroadVerdict {
	for (const allowed of config.allowedRoots) {
		if (isWithin(abs, allowed)) return { broad: false, reason: "" };
	}

	// Checked before any readdir so that "/" is never enumerated.
	if (config.broadRoots.has(abs)) {
		return { broad: true, reason: `${display(abs)} is a protected system or home-level directory` };
	}

	const direct = countRepoLike(abs);
	if (direct >= 2) {
		return {
			broad: true,
			reason: `${display(abs)} contains ${direct} git repositories or node_modules directories`,
		};
	}

	// A workspace parent such as ~/Projects has no repo children of its own,
	// but its children are workspace parents. Dependency and metadata
	// directories are skipped: descending into node_modules would both waste a
	// large readdir and risk miscounting nested packages as checkouts.
	try {
		const entries = readdirSync(abs, { withFileTypes: true });
		const limit = Math.min(entries.length, CHILD_SCAN_CAP);
		for (let i = 0; i < limit; i += 1) {
			const entry = entries[i];
			if (entry === undefined || !entry.isDirectory()) continue;
			if (entry.name === "node_modules" || entry.name.startsWith(".")) continue;
			const childPath = join(abs, entry.name);
			const nested = countRepoLike(childPath);
			if (nested >= 2) {
				return {
					broad: true,
					reason: `${display(abs)} is a workspace parent; ${display(childPath)} alone holds ${nested} repositories`,
				};
			}
		}
	} catch {
		// Ignore unreadable directories.
	}

	return { broad: false, reason: "" };
}

function resolveTarget(token: string, cwd: string): string {
	const expanded = expandHome(token);
	const absolute = resolve(cwd, expanded);
	try {
		return realpathSync(absolute);
	} catch {
		return absolute;
	}
}

// ---------------------------------------------------------------------------
// Rules
// ---------------------------------------------------------------------------

function quote(value: string): string {
	return /[\s"'$`\\*?\[\]]/.test(value) ? `'${value.replace(/'/g, `'\\''`)}'` : value;
}

const BYPASS_HINT = [
	"Bypass only if rg/fd genuinely lack a flag you need, by appending this comment:",
	"  # allow-broad-search",
].join("\n");

function suggestSearch(tool: string, parsed: ParsedSearch, targets: string[]): string {
	const pattern = parsed.pattern === undefined ? "PATTERN" : quote(parsed.pattern);
	const where = targets.length > 0 ? ` ${targets.map(display).map(quote).join(" ")}` : "";
	return FD_FAMILY.has(tool) ? `${tool} ${pattern}${where}` : `${tool} -l ${pattern}${where}`;
}

/** Returns a rejection message, or null when the segment is acceptable. */
function evaluateSegment(words: Word[], cwd: string, config: GuardConfig): string | null {
	// Skip leading environment assignments.
	let index = 0;
	while (index < words.length) {
		const word = words[index];
		if (word === undefined) break;
		if (/^[A-Za-z_][A-Za-z0-9_]*=/.test(word.value)) {
			index += 1;
			continue;
		}
		break;
	}

	const commandWord = words[index];
	if (commandWord === undefined) return null;
	const name = basename(commandWord.value);
	if (!SEARCH_COMMANDS.has(name) && name !== "rgrep") return null;

	const args = words.slice(index + 1);
	const isFind = FIND_FAMILY.has(name);
	const spec = FD_FAMILY.has(name) ? FD_FLAGS : RG_FAMILY.has(name) ? RG_FLAGS : GREP_FLAGS;
	const parsed = isFind ? parseFind(args) : parsePatternFirst(args, spec);

	const targets =
		parsed.paths.length > 0
			? parsed.paths.map((path) => resolveTarget(path, cwd))
			: [resolveTarget(".", cwd)];

	// Rule A: grep -r walks ignored directories.
	if ((GREP_FAMILY.has(name) && parsed.recursive) || name === "rgrep") {
		return [
			"Blocked: `grep -r` walks .gitignored directories (node_modules, .git, build output).",
			"Piping to `grep -v node_modules` filters output but does not prevent the traversal.",
			"",
			"Use ripgrep, which respects ignore files:",
			`  ${suggestSearch("rg", parsed, targets)}`,
			"",
			BYPASS_HINT,
		].join("\n");
	}

	// Rule B: find has no ignore-file awareness.
	if (isFind) {
		const where = targets.map(display).map(quote).join(" ");
		return [
			"Blocked: `find` ignores .gitignore and walks node_modules and build output.",
			"",
			"Use fd, which respects ignore files:",
			`  fd PATTERN ${where}`,
			"",
			BYPASS_HINT,
		].join("\n");
	}

	// Rule C: broad roots, applied to fast tools as well.
	for (const target of targets) {
		const verdict = isBroadRoot(target, config);
		if (!verdict.broad) continue;
		return [
			`Blocked: recursive search rooted at ${display(target)}.`,
			`Reason: ${verdict.reason}.`,
			"A search here walks every checkout and its dependencies. This pattern once pinned a CPU core for 18 minutes.",
			"",
			"Narrow the search to a single repository, for example:",
			`  ${suggestSearch(name, parsed, [join(target, "<repo>")])}`,
			"",
			BYPASS_HINT,
		].join("\n");
	}

	return null;
}

/**
 * Returns the working directory in effect after a segment runs.
 *
 * Agents routinely write `cd <dir> && rg <pattern>`, so a search's target must
 * be judged from the directory the chain moved to rather than the directory
 * bash was originally invoked in.
 */
function applyCd(words: Word[], cwd: string): string {
	let index = 0;
	while (index < words.length) {
		const word = words[index];
		if (word === undefined) break;
		if (/^[A-Za-z_][A-Za-z0-9_]*=/.test(word.value)) {
			index += 1;
			continue;
		}
		break;
	}

	const head = words[index];
	if (head === undefined) return cwd;
	const name = basename(head.value);
	if (name !== "cd" && name !== "pushd") return cwd;

	for (let i = index + 1; i < words.length; i += 1) {
		const arg = words[i];
		if (arg === undefined) continue;
		// `cd -` returns to OLDPWD, which we cannot know.
		if (arg.value === "-") return cwd;
		if (arg.value.startsWith("-")) continue;
		if (arg.unresolvable) return cwd;
		return resolveTarget(arg.value, cwd);
	}

	// A bare `cd` goes home; `pushd` without an argument swaps the stack.
	return name === "cd" ? HOME : cwd;
}

/** Returns a rejection message for a whole bash command, or null to allow. */
export function evaluateCommand(command: string, cwd: string, config: GuardConfig): string | null {
	if (BYPASS_PATTERN.test(command)) return null;
	let effectiveCwd = cwd;
	for (const words of segments(command)) {
		const verdict = evaluateSegment(words, effectiveCwd, config);
		if (verdict !== null) return verdict;
		effectiveCwd = applyCd(words, effectiveCwd);
	}
	return null;
}

// ---------------------------------------------------------------------------
// Extension
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
	const config = loadConfig();

	pi.on("tool_call", async (event, ctx) => {
		if (!isToolCallEventType("bash", event)) return;
		const command = event.input.command;
		if (typeof command !== "string" || command.length === 0) return;

		const verdict = evaluateCommand(command, ctx.cwd, config);
		if (verdict === null) return;

		if (ctx.hasUI) {
			ctx.ui.notify("search-guard blocked an expensive recursive search", "warning");
		}
		return { block: true, reason: verdict };
	});

	pi.registerCommand("search-guard", {
		description: "Dry-run a bash command against the search guard rules",
		handler: async (args, ctx) => {
			const command = args.trim();
			if (command.length === 0) {
				ctx.ui.notify("Usage: /search-guard <bash command to test>", "info");
				return;
			}
			const verdict = evaluateCommand(command, ctx.cwd, config);
			if (verdict === null) {
				ctx.ui.notify(`Allowed: ${command}`, "info");
				return;
			}
			ctx.ui.notify(`Blocked:\n${verdict}`, "warning");
		},
	});
}
