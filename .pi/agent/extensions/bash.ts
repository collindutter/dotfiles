/**
 * Bash override: no `cd` prefix, plus the uv guard.
 *
 * Bash already spawns in the session directory, so `cd <session dir> &&` is a
 * no-op that only clutters commands and hides them from extensions that match
 * on command names. Tells the model not to write it, and drops it when it does.
 *
 * Single owner of the `bash` tool, so uv's Python interception lives in
 * lib/uv.ts and is composed in here.
 *
 * Upstream asked for this in earendil-works/pi#7241 and #7915; both closed
 * with "can be done via extension".
 */

import { realpathSync } from "node:fs";
import { homedir } from "node:os";
import { resolve } from "node:path";
import { createBashToolDefinition, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { uvBashOptions } from "./lib/uv.ts";

/** `cd <path> &&` or `cd <path>;` at the start of a command. */
const LEADING_CD = /^\s*cd\s+(?:'([^']*)'|"([^"]*)"|([^\s;&|]+))\s*(?:&&|;)\s*/;

function canonical(path: string, cwd: string): string {
	const expanded = path === "~" || path.startsWith("~/") ? homedir() + path.slice(1) : path;
	try {
		return realpathSync(resolve(cwd, expanded));
	} catch {
		return resolve(cwd, expanded);
	}
}

/** Remove `cd` prefixes that are no-ops because they target `cwd`. */
function stripRedundantCd(command: string, cwd: string): string {
	const target = canonical(cwd, cwd);
	let out = command;
	for (;;) {
		const match = LEADING_CD.exec(out);
		if (!match) return out;
		const path = match[1] ?? match[2] ?? match[3];
		if (canonical(path, cwd) !== target) return out;
		const rest = out.slice(match[0].length);
		if (!rest.trim()) return out;
		out = rest;
	}
}

export default function (pi: ExtensionAPI) {
	const base = createBashToolDefinition(process.cwd(), uvBashOptions);

	pi.registerTool({
		...base,
		promptGuidelines: [
			...(base.promptGuidelines ?? []),
			'Never prefix a bash command with "cd" to reach the session directory, commands already run there.',
		],
		execute(toolCallId, params, signal, onUpdate, ctx) {
			const command = stripRedundantCd(params.command, ctx?.cwd || process.cwd());
			return base.execute(toolCallId, { ...params, command }, signal, onUpdate, ctx);
		},
		renderCall(args, theme, context) {
			const display =
				typeof args?.command === "string"
					? { ...args, command: stripRedundantCd(args.command, context.cwd) }
					: args;
			return base.renderCall!(display, theme, context);
		},
	});
}
