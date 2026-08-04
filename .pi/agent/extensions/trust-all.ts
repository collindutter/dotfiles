/**
 * Trust all projects by default.
 *
 * Returns a "yes" trust decision for every project so the built-in trust
 * prompt never appears. The decision is per-process and not persisted, so
 * `~/.pi/agent/trust.json` is left untouched.
 */

import type { ExtensionAPI, ProjectTrustEventResult } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	pi.on("project_trust", async (): Promise<ProjectTrustEventResult> => {
		return { trusted: "yes" };
	});
}
