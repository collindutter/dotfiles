/**
 * Workmux status tracking extension for pi.
 *
 * Reports agent status to workmux for tmux window status display.
 * See: https://workmux.raine.dev/guide/status-tracking
 *
 * Only the interactive session owning the pane reports. Headless children (the
 * `subagent` tool, or an agent shelling out to `pi -p ...`) inherit `TMUX_PANE`
 * and load this extension too, so without the mode guard a child's completion
 * marks the pane done while the parent is still working.
 *
 * "done" comes from `agent_settled`, not `agent_end`. `agent_end` fires at the
 * end of every low-level run, including runs pi follows with an auto-retry, an
 * auto-compaction, or a queued follow-up message, so reporting there paints the
 * pane done while work continues. Each report is also a separate `workmux`
 * process, so a slow `agent_end` write can land after the `working` write of
 * the run that succeeded it and strand the pane on done for that whole run.
 * `agent_settled` fires only once pi will not continue on its own.
 *
 * `workmux setup --hooks` rewrites this file from a template embedded in the
 * workmux binary, which drops all of the above.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  function setStatus(status: string) {
    pi.exec("workmux", ["set-window-status", status]).catch(() => {});
  }

  pi.on("agent_start", async (_event, ctx) => {
    if (ctx.mode !== "tui") return;
    setStatus("working");
  });

  pi.on("agent_settled", async (_event, ctx) => {
    if (ctx.mode !== "tui") return;
    // Another extension can start a new run from this event, which keeps the
    // pane working rather than settling it.
    if (!ctx.isIdle()) return;
    setStatus("done");
  });
}
