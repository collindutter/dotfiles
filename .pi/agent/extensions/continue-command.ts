/**
 * Continue command extension for pi.
 *
 * Adds `/c` to nudge the agent to keep going after an interruption without
 * having to type "continue". An optional argument overrides the default text,
 * e.g. `/c finish the refactor`.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	pi.registerCommand("c", {
		description: "Continue the interrupted turn",
		handler: async (args, ctx) => {
			if (!ctx.isIdle()) {
				ctx.ui.notify("Agent is busy.", "warning");
				return;
			}

			pi.sendUserMessage(args.trim() || "continue");
		},
	});
}
