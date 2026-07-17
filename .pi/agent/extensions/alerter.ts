/**
 * Alerter extension - macOS notifications for agent activity.
 *
 * Auto-notify on `agent_end`. When the agent finishes a prompt, fire a
 * non-blocking macOS notification (via the `alerter` CLI) summarizing the
 * final assistant message. This replaces the manual "run alerter when you
 * finish" instruction in AGENTS.md: it can't be forgotten and costs no
 * tokens. The notification is suppressed only when you're actually looking
 * at pi: the host terminal is frontmost AND (inside tmux) pi's window is the
 * active window. Being in a different tmux window still notifies.
 *
 * Configuration (environment variables):
 *   PI_ALERTER_DISABLED            Any non-empty value disables auto-notify.
 *   PI_ALERTER_NOTIFY_WHEN_FOCUSED Notify even when the terminal is frontmost.
 *   PI_ALERTER_MIN_SECONDS         When focus can't be determined, only notify
 *                                  if the run lasted at least this long (default 10).
 *   PI_ALERTER_TIMEOUT             Auto-dismiss the notification after N seconds (default 30).
 *
 * Manual command:
 *   /alerter-test   Fire a test notification and report detected focus state.
 *
 * Requires the `alerter` CLI (`brew install vjeantet/tap/alerter`) and macOS.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { spawn } from "node:child_process";
import { basename } from "node:path";

const NOTIFY_TITLE = "Pi";
const MAX_BODY_LENGTH = 220;

function envFlag(name: string): boolean {
  const value = process.env[name];
  return value !== undefined && value !== "" && value !== "0" && value !== "false";
}

function envNumber(name: string, fallback: number): number {
  const raw = process.env[name];
  if (raw === undefined || raw === "") return fallback;
  const parsed = Number(raw);
  return Number.isFinite(parsed) ? parsed : fallback;
}

interface AssistantLike {
  role: "assistant";
  content: Array<{ type: string; text?: string }>;
  stopReason?: string;
}

function asAssistant(message: unknown): AssistantLike | undefined {
  if (typeof message !== "object" || message === null) return undefined;
  const record = message as Record<string, unknown>;
  if (record.role !== "assistant" || !Array.isArray(record.content)) return undefined;
  return record as unknown as AssistantLike;
}

/** Last assistant message of the run, scanning from the end. */
function lastAssistant(messages: readonly unknown[]): AssistantLike | undefined {
  for (let i = messages.length - 1; i >= 0; i--) {
    const assistant = asAssistant(messages[i]);
    if (assistant) return assistant;
  }
  return undefined;
}

function assistantText(assistant: AssistantLike): string {
  const text = assistant.content
    .filter((block) => block.type === "text" && typeof block.text === "string")
    .map((block) => block.text as string)
    .join(" ")
    .replace(/\s+/g, " ")
    .trim();
  if (text.length <= MAX_BODY_LENGTH) return text;
  return text.slice(0, MAX_BODY_LENGTH - 1).trimEnd() + "…";
}

/**
 * App display names that mean "the terminal pi is running in is frontmost".
 * Derived from TERM_PROGRAM, TERM (covers tmux/screen where TERM_PROGRAM is the
 * multiplexer), and terminal-specific env vars. Empty when undetectable.
 */
function frontmostTerminalNames(): Set<string> {
  const names = new Set<string>();
  const add = (...values: string[]) => {
    for (const value of values) names.add(value.toLowerCase());
  };

  switch (process.env.TERM_PROGRAM) {
    case "Apple_Terminal":
      add("Terminal");
      break;
    case "iTerm.app":
      add("iTerm2", "iTerm");
      break;
    case "vscode":
      add("Code", "Code - Insiders", "Cursor", "Electron");
      break;
    case "WezTerm":
      add("WezTerm");
      break;
    case "ghostty":
      add("Ghostty");
      break;
    case "Hyper":
      add("Hyper");
      break;
    case "Tabby":
      add("Tabby");
      break;
    case "rio":
      add("Rio");
      break;
  }

  const term = process.env.TERM ?? "";
  if (term.includes("ghostty")) add("Ghostty");
  if (term.includes("kitty")) add("kitty");
  if (term.includes("alacritty")) add("Alacritty");
  if (term.includes("wezterm")) add("WezTerm");
  if (term.includes("rio")) add("Rio");

  if (process.env.GHOSTTY_RESOURCES_DIR || process.env.GHOSTTY_BIN_DIR) add("Ghostty");
  if (process.env.KITTY_WINDOW_ID) add("kitty");
  if (process.env.ALACRITTY_WINDOW_ID || process.env.ALACRITTY_SOCKET) add("Alacritty");
  if (process.env.WEZTERM_PANE || process.env.WEZTERM_EXECUTABLE) add("WezTerm");
  if (process.env.ITERM_SESSION_ID) add("iTerm2", "iTerm");
  if (process.env.VSCODE_INJECTION || process.env.VSCODE_PID) add("Code", "Cursor");

  return names;
}

export default function (pi: ExtensionAPI) {
  let runStartedAt: number | undefined;

  /** Frontmost app's display name via lsappinfo, or undefined if undetectable. */
  async function frontmostAppName(signal?: AbortSignal): Promise<string | undefined> {
    try {
      const front = await pi.exec("lsappinfo", ["front"], { signal, timeout: 2000 });
      const asn = front.stdout.trim().replace(/^"|"$/g, "");
      if (!asn) return undefined;
      const info = await pi.exec("lsappinfo", ["info", "-only", "name", asn], {
        signal,
        timeout: 2000,
      });
      // Output looks like: "LSDisplayName"="Ghostty"  (older macOS: "name"="…")
      const match = info.stdout.match(/="([^"]*)"\s*$/m) ?? info.stdout.match(/"([^"]*)"\s*$/m);
      return match ? match[1] : undefined;
    } catch {
      return undefined;
    }
  }

  /**
   * Whether pi's tmux window is the active window in its session, or undefined
   * when not in tmux or the query fails. The attached-client signals
   * (session_attached, list-clients) are unreliable across multi-session
   * setups, so window_active is the signal that tracks what's on screen.
   */
  async function isTmuxWindowActive(signal?: AbortSignal): Promise<boolean | undefined> {
    if (!process.env.TMUX) return undefined;
    try {
      const args = ["display-message", "-p"];
      const pane = process.env.TMUX_PANE;
      if (pane) args.push("-t", pane);
      args.push("#{window_active}");
      const res = await pi.exec("tmux", args, { signal, timeout: 2000 });
      const out = res.stdout.trim();
      if (out === "1") return true;
      if (out === "0") return false;
      return undefined;
    } catch {
      return undefined;
    }
  }

  /**
   * Whether you're actually looking at pi right now.
   * true = watching (suppress), false = not watching (notify), undefined = can't tell.
   */
  async function isTerminalFocused(signal?: AbortSignal): Promise<boolean | undefined> {
    const expected = frontmostTerminalNames();
    let appFocused: boolean | undefined;
    if (expected.size === 0) {
      appFocused = undefined;
    } else {
      const front = await frontmostAppName(signal);
      appFocused = front === undefined ? undefined : expected.has(front.toLowerCase());
    }

    // Host terminal definitely not frontmost: you're not watching pi.
    if (appFocused === false) return false;

    // Inside tmux, pi is only on screen when its window is the active one.
    if (process.env.TMUX) {
      const windowActive = await isTmuxWindowActive(signal);
      if (windowActive === false) return false;
      if (appFocused === true && windowActive === true) return true;
      return undefined;
    }

    // Outside tmux, app focus alone decides.
    return appFocused;
  }

  /** Fire a non-blocking notification (auto-dismisses, never waits on the user). */
  function notify(body: string, subtitle?: string): void {
    const timeout = String(Math.max(0, Math.round(envNumber("PI_ALERTER_TIMEOUT", 30))));
    const group = `pi:${pi.getSessionName() ?? process.cwd()}`;
    const args = [
      "--title",
      NOTIFY_TITLE,
      "--message",
      body,
      "--timeout",
      timeout,
      "--group",
      group,
    ];
    if (subtitle) args.push("--subtitle", subtitle);

    try {
      const child = spawn("alerter", args, { detached: true, stdio: "ignore" });
      child.on("error", () => {});
      child.unref();
    } catch {
      // alerter missing or non-macOS: silently skip auto-notify.
    }
  }

  function subtitleForCwd(): string {
    const name = pi.getSessionName();
    if (name) return name;
    return basename(process.cwd());
  }

  pi.on("agent_start", () => {
    runStartedAt = Date.now();
  });

  pi.on("agent_end", async (event, ctx) => {
    const startedAt = runStartedAt;
    runStartedAt = undefined;

    if (envFlag("PI_ALERTER_DISABLED")) return;
    if (!ctx.hasUI) return;

    const assistant = lastAssistant(event.messages);
    // Don't ping when the user aborted the run themselves; they're at the keyboard.
    if (assistant?.stopReason === "aborted") return;

    const focused = await isTerminalFocused(ctx.signal);
    if (focused === true && !envFlag("PI_ALERTER_NOTIFY_WHEN_FOCUSED")) return;
    if (focused === undefined) {
      const minSeconds = envNumber("PI_ALERTER_MIN_SECONDS", 10);
      const elapsedSeconds = startedAt ? (Date.now() - startedAt) / 1000 : 0;
      if (elapsedSeconds < minSeconds) return;
    }

    const body = assistant ? assistantText(assistant) : "";
    notify(body || "Task finished.", subtitleForCwd());
  });

  pi.registerCommand("alerter-test", {
    description: "Fire a test macOS notification and report detected focus state",
    handler: async (_args, ctx) => {
      const expected = frontmostTerminalNames();
      const front = await frontmostAppName(ctx.signal);
      const windowActive = await isTmuxWindowActive(ctx.signal);
      const focused = await isTerminalFocused(ctx.signal);
      notify("Test notification from Pi.", subtitleForCwd());
      ctx.ui.notify(
        `Sent test alert. frontmost=${front ?? "unknown"}, ` +
          `terminalNames=[${[...expected].join(", ") || "none"}], ` +
          `tmuxWindowActive=${windowActive === undefined ? "n/a" : windowActive}, ` +
          `focused=${focused === undefined ? "unknown" : focused}`,
        "info",
      );
    },
  });
}
