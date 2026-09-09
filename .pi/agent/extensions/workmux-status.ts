/**
 * Workmux status tracking extension for pi.
 *
 * Reports agent status to workmux for tmux window status display.
 * See: https://workmux.raine.dev/guide/status-tracking
 *
 * This is the sole writer of the pane's status. Every `set-window-status` is a
 * separate `workmux` process, so independent writers reorder: a slow "done"
 * write lands after the "working" write that logically replaced it and strands
 * the pane. Instead, four sources feed one state machine, and one serialized
 * writer publishes the newest desired status:
 *
 *   run lifecycle          agent_start / agent_settled
 *   pending question       rpiv:ask-user:blocked (@juicesharp/rpiv-ask-user-question)
 *   async subagents        launch receipts + subagent:async-started / -complete
 *   subagent attention     subagent:control-event (pi-subagents)
 *
 * State priority is waiting > working > done. A question on screen or an async
 * child blocked on a reply outranks in-flight work, and in-flight work includes
 * detached subagent runs: the parent settling while children still run is not a
 * finished pane.
 *
 * "done" comes from `agent_settled`, not `agent_end`. `agent_end` fires at the
 * end of every low-level run, including runs pi follows with an auto-retry, an
 * auto-compaction, or a queued follow-up message, so reporting there paints the
 * pane done while work continues. `agent_settled` fires only once pi will not
 * continue on its own.
 *
 * Only the interactive session owning the pane reports. Headless children (the
 * `subagent` tool, or an agent shelling out to `pi -p ...`) inherit `TMUX_PANE`
 * and load this extension too, so without the mode guard a child's completion
 * marks the pane done while the parent is still working.
 *
 * `workmux setup --hooks` rewrites this file from a template embedded in the
 * workmux binary, which drops all of the above.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/**
 * Event bus channel published by @juicesharp/rpiv-ask-user-question while a
 * questionnaire awaits an answer. The channel name and its `{ active }` payload
 * are part of that package's stable event contract, so they are inlined rather
 * than imported: the extension tree and the pi package tree resolve separately,
 * and this extension must keep loading when the package is absent.
 */
const ASK_USER_BLOCKED_EVENT = "rpiv:ask-user:blocked";

/**
 * pi-subagents lifecycle channels, inlined for the same reason. Payload fields
 * used here (`id`, `runId`, and `{ source, event: { type, reason, runId } }`) are
 * the ones its own Herdr status bridge consumes.
 */
const SUBAGENT_ASYNC_STARTED_EVENT = "subagent:async-started";
const SUBAGENT_ASYNC_COMPLETE_EVENT = "subagent:async-complete";
const SUBAGENT_CONTROL_EVENT = "subagent:control-event";

/**
 * `needs_attention` reasons that mean the pane wants a human. A child blocked on
 * a supervisor reply and a child that failed its completion guard both sit until
 * someone answers. The rest (`idle`, `tool_open_threshold`, `tool_failures`) are
 * watchdog nudges the parent handles on its own turn, and a long poll loop trips
 * them while the pane is working exactly as intended.
 */
const INPUT_REASONS = new Set(["supervisor_request", "completion_guard"]);

/**
 * Attention is latched from one event and no counterpart clears it, so a notice
 * that lands after the parent settles would strand the pane. The latch expires
 * on its own; a child that is still blocked re-notifies.
 */
const ATTENTION_TTL_MS = 90_000;

/** Tool pi-subagents registers; its results carry the launch receipts read below. */
const SUBAGENT_TOOL = "subagent";

/**
 * An async completion normally wakes the parent with a queued turn, so settling
 * the pane the instant the last run finishes flashes done before that turn
 * repaints it working. Wait out the wake; any state change cancels the timer.
 */
const COMPLETION_WAKE_GRACE_MS = 2_000;

type Status = "working" | "waiting" | "done";

function record(value: unknown): Record<string, unknown> | undefined {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : undefined;
}

function id(value: unknown, ...keys: string[]): string | undefined {
  const data = record(value);
  if (!data) return undefined;
  for (const key of keys) {
    const candidate = data[key];
    if (typeof candidate === "string" && candidate) return candidate;
  }
  return undefined;
}

/**
 * Run id from a `subagent` launch receipt. `asyncDir` marks a run that outlives
 * the tool call; a `management` result carries one for a run it only reports on.
 *
 * Async workflows run inside this process and publish no
 * `subagent:async-started`, so the receipt is their only launch signal. Async
 * single and chain runs emit both, and the run id is the same in each.
 */
function launchedRunId(event: unknown): string | undefined {
  const data = record(event);
  if (!data || data.toolName !== SUBAGENT_TOOL || data.isError === true) return undefined;
  const details = record(data.details);
  if (!details || details.mode === "management" || typeof details.asyncDir !== "string") return undefined;
  return id(details, "runId", "asyncId");
}

/** Async run waiting on someone: a child blocked on a supervisor reply, or one that failed its completion guard. */
function attentionRunId(value: unknown): string | undefined {
  const data = record(value);
  if (!data || data.source !== "async") return undefined;
  const event = record(data.event);
  if (!event || event.type !== "needs_attention") return undefined;
  if (typeof event.reason !== "string" || !INPUT_REASONS.has(event.reason)) return undefined;
  return id(event, "runId");
}

export default function (pi: ExtensionAPI) {
  let paneOwner = false;
  let running = false;
  let questionActive = false;
  const activeRuns = new Set<string>();
  const attentionRuns = new Map<string, ReturnType<typeof setTimeout>>();

  let desired: Status | undefined;
  let writing = false;
  let settleTimer: ReturnType<typeof setTimeout> | undefined;

  function dropAttention(runId: string): boolean {
    const timer = attentionRuns.get(runId);
    if (timer === undefined) return false;
    clearTimeout(timer);
    attentionRuns.delete(runId);
    return true;
  }

  function clearAttention() {
    for (const timer of attentionRuns.values()) clearTimeout(timer);
    attentionRuns.clear();
  }

  function raiseAttention(runId: string) {
    dropAttention(runId);
    const timer = setTimeout(() => {
      attentionRuns.delete(runId);
      publish();
    }, ATTENTION_TTL_MS);
    timer.unref?.();
    attentionRuns.set(runId, timer);
  }

  function write(status: Status) {
    desired = status;
    if (writing) return;
    writing = true;
    void (async () => {
      let written: Status | undefined;
      while (desired && desired !== written) {
        const next = desired;
        // A status the pane no longer wants is superseded by the next loop pass,
        // never by a second concurrent process.
        await pi.exec("workmux", ["set-window-status", next]).then(
          () => {},
          () => {},
        );
        written = next;
      }
      writing = false;
    })();
  }

  function publish(delayMs = 0) {
    if (!paneOwner) return;
    if (settleTimer) {
      clearTimeout(settleTimer);
      settleTimer = undefined;
    }
    const next: Status =
      questionActive || attentionRuns.size > 0
        ? "waiting"
        : running || activeRuns.size > 0
          ? "working"
          : "done";
    // A pane that never reported work has nothing to mark done.
    if (next === desired || (next === "done" && desired === undefined)) return;
    if (delayMs > 0) {
      settleTimer = setTimeout(() => {
        settleTimer = undefined;
        publish();
      }, delayMs);
      settleTimer.unref?.();
      return;
    }
    write(next);
  }

  pi.on("session_start", async (_event, ctx) => {
    if (ctx.mode !== "tui") return;
    paneOwner = true;
    // Completion delivery is session-scoped, so runs from a replaced session
    // never resolve here and would strand the pane on "working".
    activeRuns.clear();
    clearAttention();
    // Makes the pi process visible to `workmux dashboard`, `send`, `capture`,
    // and `reap-agents`.
    await pi.exec("workmux", ["register-agent"]).then(
      () => {},
      () => {},
    );
  });

  pi.on("agent_start", async (_event, ctx) => {
    if (ctx.mode !== "tui") return;
    paneOwner = true;
    running = true;
    // The turn is the parent acting on whatever a child raised.
    clearAttention();
    publish();
  });

  pi.on("agent_settled", async (_event, ctx) => {
    if (ctx.mode !== "tui") return;
    // Another extension can start a new run from this event, which keeps the
    // pane working rather than settling it.
    if (!ctx.isIdle()) return;
    running = false;
    publish();
  });

  pi.on("tool_result", async (event, ctx) => {
    if (ctx.mode !== "tui") return;
    const runId = launchedRunId(event);
    if (!runId) return;
    activeRuns.add(runId);
    publish();
  });

  pi.events.on(ASK_USER_BLOCKED_EVENT, (data) => {
    questionActive = record(data)?.active === true;
    publish();
  });

  pi.events.on(SUBAGENT_ASYNC_STARTED_EVENT, (data) => {
    const runId = id(data, "id");
    if (!runId) return;
    activeRuns.add(runId);
    publish();
  });

  pi.events.on(SUBAGENT_ASYNC_COMPLETE_EVENT, (data) => {
    const runId = id(data, "runId", "id");
    if (!runId) return;
    const wasActive = activeRuns.delete(runId);
    const wasBlocked = dropAttention(runId);
    if (!wasActive && !wasBlocked) return;
    publish(activeRuns.size === 0 && !running ? COMPLETION_WAKE_GRACE_MS : 0);
  });

  pi.events.on(SUBAGENT_CONTROL_EVENT, (data) => {
    const runId = attentionRunId(data);
    if (!runId) return;
    raiseAttention(runId);
    publish();
  });
}
