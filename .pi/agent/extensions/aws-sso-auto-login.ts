/**
 * AWS SSO Auto-Login extension
 *
 * When a `bash` tool call fails with an expired AWS SSO token, this extension
 * offers to run `aws sso login` for you, then re-runs the original command and
 * replaces the error result with the retry output — so the agent never sees the
 * failure.
 *
 * It extracts the AWS profile from the failing command in this order:
 *   1. `AWS_PROFILE=foo ...` inline env var on the command
 *   2. `--profile foo` / `--profile=foo` flag anywhere in the command
 *   3. pi's own `AWS_PROFILE` env var
 *
 * Matches common SSO-expiry error strings emitted by AWS CLI v2 / botocore.
 *
 * Manual commands:
 *   /aws-sso-login              Run `aws sso login` using the env profile (if any)
 *   /aws-sso-login my-profile   Run `aws sso login --profile my-profile`
 */

import type {
  ExtensionAPI,
  ToolResultEvent,
} from "@mariozechner/pi-coding-agent";
import { isBashToolResult } from "@mariozechner/pi-coding-agent";

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

function buildLoginArgs(profile: string | undefined): string[] {
  return profile ? ["sso", "login", "--profile", profile] : ["sso", "login"];
}

export default function (pi: ExtensionAPI) {
  pi.on("tool_result", async (event, ctx) => {
    if (!isBashToolResult(event)) return undefined;
    if (!event.isError) return undefined;

    const text = contentToText(event.content);
    if (!isSsoExpired(text)) return undefined;

    const command = String(event.input.command ?? "");
    if (!command) return undefined;

    const profile = extractProfile(command);
    const label = profile ? `profile '${profile}'` : "default profile";

    if (!ctx.hasUI) {
      // Non-interactive mode: we can't prompt, so leave the error for the agent.
      return undefined;
    }

    const ok = await ctx.ui.confirm(
      "AWS SSO token expired",
      `Run \`aws sso login${profile ? ` --profile ${profile}` : ""}\` now, then retry the command?`,
    );
    if (!ok) return undefined;

    // 1) Refresh the SSO session.
    ctx.ui.setStatus("aws-sso", `aws sso login (${label})…`);
    try {
      const login = await pi.exec("aws", buildLoginArgs(profile), {
        signal: ctx.signal,
        timeout: 5 * 60_000, // 5 min is enough for the browser round-trip
      });
      if (login.code !== 0) {
        ctx.ui.setStatus("aws-sso", undefined);
        const msg = (login.stderr || login.stdout || "")
          .trim()
          .split("\n")
          .slice(-3)
          .join("\n");
        ctx.ui.notify(
          `aws sso login failed (exit ${login.code}):\n${msg}`,
          "error",
        );
        return undefined;
      }
    } catch (err) {
      ctx.ui.setStatus("aws-sso", undefined);
      ctx.ui.notify(`aws sso login failed: ${(err as Error).message}`, "error");
      return undefined;
    }

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

  // Manual trigger: /aws-sso-login [profile]
  pi.registerCommand("aws-sso-login", {
    description:
      "Run `aws sso login` (optionally with a profile) without waiting for an error",
    handler: async (args, ctx) => {
      const profile = args.trim() || process.env.AWS_PROFILE || undefined;
      const label = profile ? `profile '${profile}'` : "default profile";
      ctx.ui.setStatus("aws-sso", `aws sso login (${label})…`);
      try {
        const login = await pi.exec("aws", buildLoginArgs(profile), {
          timeout: 5 * 60_000,
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
          return;
        }
        ctx.ui.notify(`AWS SSO logged in (${label})`, "info");
      } catch (err) {
        ctx.ui.setStatus("aws-sso", undefined);
        ctx.ui.notify(
          `aws sso login failed: ${(err as Error).message}`,
          "error",
        );
      }
    },
  });
}
