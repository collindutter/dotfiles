/**
 * Caveman mode for pi.
 *
 * Appends terse-response instructions to the system prompt on every turn via
 * `before_agent_start`, so the agent answers in compressed "caveman" style.
 * Off by default; toggle with `/caveman on|off` (no argument toggles).
 *
 * Code blocks, commit messages, and PR descriptions always stay full verbosity.
 *
 * Source: https://perrotta.dev/2026/07/pi-caveman-mode/
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const INSTRUCTIONS = `Caveman mode: on. Respond terse. Drop articles (a/an/the), filler (just/really/basically), pleasantries, hedging. Fragments OK. Short synonyms. Technical terms exact. Pattern: [thing] [action] [reason]. [next step]. Example, not: "Sure! I'd be happy to help you with that." yes: "Bug in auth middleware. Fix:"
Boundaries, always: code blocks, commit messages, and PR descriptions stay normal full verbosity, never compressed. Drop caveman style for security warnings, irreversible/destructive actions, or when the user seems confused, resume caveman after.`;

export default function cavemanExtension(pi: ExtensionAPI) {
	let on = false;

	const applyStatus = (ctx: ExtensionContext) => {
		ctx.ui.setStatus("caveman", on ? "[caveman]" : undefined);
	};

	pi.on("session_start", async (_event, ctx) => applyStatus(ctx));

	pi.on("before_agent_start", (event) => {
		if (!on) return undefined;
		return { systemPrompt: `${event.systemPrompt}\n\n${INSTRUCTIONS}` };
	});

	pi.registerCommand("caveman", {
		description: "Toggle caveman terse-response mode: on|off (default: off)",
		handler: async (args, ctx) => {
			const arg = args.trim().toLowerCase();
			if (arg === "off" || arg === "stop" || arg === "normal") on = false;
			else if (arg === "on" || arg === "start") on = true;
			else if (arg === "") on = !on;
			else {
				ctx.ui.notify(`Unknown arg "${arg}". Use: on | off`, "error");
				return;
			}
			applyStatus(ctx);
			ctx.ui.notify(on ? "Caveman mode on." : "Caveman mode off.", "info");
		},
	});
}
