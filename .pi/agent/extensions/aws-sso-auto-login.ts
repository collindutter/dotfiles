/**
 * AWS SSO Auto-Login extension
 *
 * Keeps the AWS SSO session fresh without you ever running `aws sso login`:
 *
 *   1. On startup, it probes the session with `aws sts get-caller-identity`.
 *      That probe lets AWS silently refresh the access token from the cached
 *      refresh token when possible, so the browser only opens when a genuine
 *      interactive login is required. If one is needed, it runs `aws sso login`
 *      automatically — you click through the browser and then start working.
 *
 *   2. If a `bash` tool call later fails with an expired-token error mid-task,
 *      it runs `aws sso login` (you click the browser), re-runs the original
 *      command, and replaces the error with the retry output — so the agent
 *      never sees the failure and resumes on its own.
 *
 *   3. If the LLM provider request itself fails with an expired-token error
 *      (e.g. Amazon Bedrock models authenticated via AWS SSO), it runs
 *      `aws sso login` (you click the browser) and re-sends your last prompt,
 *      so a mid-session expiry no longer forces you to quit pi and re-auth.
 *
 * Profile resolution for the reactive path, in order:
 *   1. `AWS_PROFILE=foo ...` inline env var on the failing command
 *   2. `--profile foo` / `--profile=foo` flag anywhere in the command
 *   3. pi's own `AWS_PROFILE` env var
 *
 * The startup probe uses pi's own `AWS_PROFILE` env var.
 *
 * Matches common SSO-expiry error strings emitted by AWS CLI v2 / botocore.
 */

import type {
  ExtensionAPI,
  ExtensionContext,
  ToolResultEvent,
} from "@earendil-works/pi-coding-agent";
import { isBashToolResult } from "@earendil-works/pi-coding-agent";

const SSO_EXPIRED_PATTERNS: RegExp[] = [
  /Token is expired\.\s*To refresh this SSO session run ['"]?aws sso login['"]?/i,
  /Error when retrieving token from sso:\s*Token has expired and refresh failed/i,
  /The SSO session associated with this profile has expired or is otherwise invalid/i,
  /\bUnauthorizedSSOTokenError\b/,
  /Error loading SSO Token:.*(?:expired|does not exist|not found)/i,
  /The provided token has expired/i,
];

function isSsoExpired(text: string): boolean {
  return SSO_EXPIRED_PATTERNS.some((p) => p.test(text));
}

function extractProfile(command: string): string | undefined {
  // Inline env: AWS_PROFILE=foo ... (allow quoted values)
  const envMatch = command.match(
    /(?:^|\s|;|&&|\|\|)AWS_PROFILE=(?:"([^"]+)"|'([^']+)'|([^\s"';&|]+))/,
  );
  if (envMatch) return envMatch[1] ?? envMatch[2] ?? envMatch[3];

  // --profile foo  or  --profile=foo
  const flagMatch = command.match(
    /--profile(?:[=\s]+)(?:"([^"]+)"|'([^']+)'|([^\s"';&|]+))/,
  );
  if (flagMatch) return flagMatch[1] ?? flagMatch[2] ?? flagMatch[3];

  return process.env.AWS_PROFILE || undefined;
}

function contentToText(content: ToolResultEvent["content"]): string {
  return content
    .filter(
      (c): c is { type: "text"; text: string } =>
        c.type === "text" && typeof c.text === "string",
    )
    .map((c) => c.text)
    .join("\n");
}

function profileLabel(profile: string | undefined): string {
  return profile ? `profile '${profile}'` : "default profile";
}

/** True when an assistant message ended in an SSO-expiry provider error. */
function isSsoErroredAssistant(message: { role?: string }): boolean {
  const m = message as {
    role?: string;
    stopReason?: string;
    errorMessage?: string;
  };
  return (
    m.role === "assistant" &&
    m.stopReason === "error" &&
    isSsoExpired(String(m.errorMessage ?? ""))
  );
}

/** Plain text of a message, joining text parts when content is an array. */
function messageText(message: { content?: unknown }): string | undefined {
  const content = message.content;
  if (typeof content === "string") return content.trim() || undefined;
  if (Array.isArray(content)) {
    const text = content
      .filter(
        (p): p is { type: "text"; text: string } =>
          !!p &&
          typeof p === "object" &&
          (p as { type?: unknown }).type === "text" &&
          typeof (p as { text?: unknown }).text === "string",
      )
      .map((p) => p.text)
      .join("\n")
      .trim();
    return text || undefined;
  }
  return undefined;
}

function buildLoginArgs(profile: string | undefined): string[] {
  return profile ? ["sso", "login", "--profile", profile] : ["sso", "login"];
}

/**
 * Probe whether the SSO session needs an interactive login. Runs
 * `aws sts get-caller-identity`, which triggers AWS's silent refresh-token
 * flow when possible, so this only reports `true` when a browser login is
 * genuinely required (expired/absent session). Probe failures unrelated to
 * SSO expiry (missing binary, network, no credentials) report `false` so we
 * never pop a browser unnecessarily.
 */
async function ssoSessionNeedsLogin(
  pi: ExtensionAPI,
  profile: string | undefined,
  signal: AbortSignal | undefined,
): Promise<boolean> {
  const args = ["sts", "get-caller-identity"];
  if (profile) args.push("--profile", profile);
  try {
    const probe = await pi.exec("aws", args, { signal, timeout: 20_000 });
    if (probe.code === 0) return false;
    return isSsoExpired(`${probe.stdout}\n${probe.stderr}`);
  } catch {
    return false;
  }
}

/**
 * Run `aws sso login`, opening a browser for the user to approve. Returns true
 * on success. Manages the status indicator and surfaces failures as notifies.
 */
async function runSsoLogin(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  profile: string | undefined,
): Promise<boolean> {
  ctx.ui.setStatus("aws-sso", `aws sso login (${profileLabel(profile)})…`);
  try {
    const login = await pi.exec("aws", buildLoginArgs(profile), {
      signal: ctx.signal,
      timeout: 5 * 60_000, // 5 min is enough for the browser round-trip
    });
    ctx.ui.setStatus("aws-sso", undefined);
    if (login.code !== 0) {
      const msg = (login.stderr || login.stdout || "")
        .trim()
        .split("\n")
        .slice(-3)
        .join("\n");
      ctx.ui.notify(
        `aws sso login failed (exit ${login.code}):\n${msg}`,
        "error",
      );
      return false;
    }
    return true;
  } catch (err) {
    ctx.ui.setStatus("aws-sso", undefined);
    ctx.ui.notify(`aws sso login failed: ${(err as Error).message}`, "error");
    return false;
  }
}

export default function (pi: ExtensionAPI) {
  // Proactive: on a fresh launch, refresh the SSO session before any work so a
  // login (if needed) happens up front rather than mid-task. Resumes/forks
  // reuse the same cached token, so we only probe on "startup".
  pi.on("session_start", async (event, ctx) => {
    if (event.reason !== "startup") return;
    if (!ctx.hasUI) return; // No one to click the browser in non-interactive mode.

    const profile = process.env.AWS_PROFILE || undefined;
    const label = profileLabel(profile);

    ctx.ui.setStatus("aws-sso", "checking AWS SSO session…");
    const needsLogin = await ssoSessionNeedsLogin(pi, profile, ctx.signal);
    ctx.ui.setStatus("aws-sso", undefined);
    if (!needsLogin) return;

    ctx.ui.notify(
      `AWS SSO session expired (${label}); running \`aws sso login\` — approve in the browser…`,
      "info",
    );
    if (await runSsoLogin(pi, ctx, profile)) {
      ctx.ui.notify(`AWS SSO session ready (${label})`, "info");
    }
  });

  // Reactive: a bash command failed with an expired-token error mid-task.
  pi.on("tool_result", async (event, ctx) => {
    if (!isBashToolResult(event)) return undefined;
    if (!event.isError) return undefined;

    const text = contentToText(event.content);
    if (!isSsoExpired(text)) return undefined;

    const command = String(event.input.command ?? "");
    if (!command) return undefined;

    const profile = extractProfile(command);
    const label = profileLabel(profile);

    if (!ctx.hasUI) {
      // Non-interactive mode: no one can click through the browser, so leave
      // the error for the agent.
      return undefined;
    }

    // 1) Refresh the SSO session automatically. A browser window opens for the
    //    user to approve; we wait for it to complete, then retry the command.
    ctx.ui.notify(
      `AWS SSO token expired (${label}); running \`aws sso login\` — approve in the browser…`,
      "info",
    );
    if (!(await runSsoLogin(pi, ctx, profile))) return undefined;

    // 2) Retry the original bash command through a login shell so the user's
    //    usual PATH / env (aws binary, profile overrides) are preserved.
    ctx.ui.setStatus("aws-sso", "SSO refreshed, retrying command…");
    try {
      const retry = await pi.exec("bash", ["-lc", command], {
        signal: ctx.signal,
        cwd: ctx.cwd,
      });
      ctx.ui.setStatus("aws-sso", undefined);
      ctx.ui.notify(
        `AWS SSO refreshed (${label}); original command re-run`,
        "info",
      );

      const combined = [retry.stdout, retry.stderr]
        .filter(Boolean)
        .join("\n")
        .trim();
      const header = `[aws-sso-auto-login] SSO session refreshed for ${label}; command was re-executed automatically.\n`;
      return {
        content: [{ type: "text", text: header + (combined || "(no output)") }],
        isError: retry.code !== 0,
      };
    } catch (err) {
      ctx.ui.setStatus("aws-sso", undefined);
      ctx.ui.notify(
        `Retry after SSO login failed: ${(err as Error).message}`,
        "error",
      );
      return undefined;
    }
  });

  // Reactive: the LLM provider request itself failed with an expired-SSO token
  // (e.g. Amazon Bedrock models authed via AWS SSO). The agent loop has ended
  // in error, so we refresh the session and re-send the user's last prompt.
  let ssoRecoveryInFlight = false;
  let lastSsoRecoveryAt = 0;
  pi.on("agent_end", async (event, ctx) => {
    if (!ctx.hasUI) return;

    const errored = [...event.messages]
      .reverse()
      .find((m) => isSsoErroredAssistant(m));
    if (!errored) return;

    if (ssoRecoveryInFlight) return;
    // Guard against tight loops: if a fresh login still left us expired, stop.
    if (Date.now() - lastSsoRecoveryAt < 30_000) {
      ctx.ui.notify(
        "AWS SSO is still failing right after a re-login; run `aws sso login` manually.",
        "error",
      );
      return;
    }

    ssoRecoveryInFlight = true;
    try {
      const profile = process.env.AWS_PROFILE || undefined;
      ctx.ui.notify(
        `AWS SSO session expired during the model request (${profileLabel(profile)}); running \`aws sso login\` — approve in the browser…`,
        "info",
      );
      if (!(await runSsoLogin(pi, ctx, profile))) return;
      lastSsoRecoveryAt = Date.now();

      const lastUser = [...event.messages]
        .reverse()
        .find((m) => m.role === "user");
      const text = lastUser ? messageText(lastUser) : undefined;
      if (text) {
        ctx.ui.notify("AWS SSO refreshed; retrying your last message…", "info");
        // We are still inside the agent lifecycle here, so the runtime is not
        // idle; queue the retry as a follow-up turn rather than sending now.
        if (ctx.isIdle()) {
          pi.sendUserMessage(text);
        } else {
          pi.sendUserMessage(text, { deliverAs: "followUp" });
        }
      } else {
        ctx.ui.notify(
          "AWS SSO refreshed; re-send your last message to continue.",
          "info",
        );
      }
    } finally {
      ssoRecoveryInFlight = false;
    }
  });
}
