import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	let primeOutput: string | undefined;
	let delivered = false;

	pi.on("session_start", async (event, ctx) => {
		if (event.reason === "reload") return;

		primeOutput = undefined;
		delivered = false;

		const result = await pi.exec("aven", ["prime"], {
			cwd: ctx.cwd,
			timeout: 30_000,
		});

		if (result.code !== 0) {
			ctx.ui.notify(
				`aven prime failed: ${result.stderr.trim() || `exit code ${result.code}`}`,
				"error",
			);
			return;
		}

		primeOutput = result.stdout.trim();
	});

	pi.on("before_agent_start", async () => {
		if (delivered || !primeOutput) return;

		delivered = true;

		return {
			message: {
				customType: "aven-prime",
				content: primeOutput,
				display: false,
			},
		};
	});
}
