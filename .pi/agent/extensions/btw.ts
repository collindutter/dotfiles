/**
 * /btw side-chat that doesn't bloat the main thread.
 *
 * Opens an interactive side chat. The LLM sees your full main-thread context and
 * answers, but nothing is written back into the main conversation history, so
 * follow-up questions don't cost you tokens on every subsequent main-thread turn.
 *
 * Usage:
 *   /btw                open the side chat (type questions interactively)
 *   /btw <question>     seed an initial question
 *
 * Inspired by Claude Code's /btw and https://github.com/patriceckhart/pi-btw,
 * reimplemented against the @earendil-works API.
 * Source: https://perrotta.dev/2026/07/pi-/btw-side-chat/
 */

import type { ImageContent, Message, TextContent, UserMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, SessionEntry } from "@earendil-works/pi-coding-agent";
import { convertToLlm, getMarkdownTheme } from "@earendil-works/pi-coding-agent";
import {
	type Component,
	type Focusable,
	Input,
	Loader,
	Markdown,
	matchesKey,
	truncateToWidth,
	wrapTextWithAnsi,
} from "@earendil-works/pi-tui";

interface BtwMessage {
	role: "user" | "assistant";
	text: string;
}

/**
 * Rewrites a conversation so it carries no tool calls, tool results, or thinking
 * blocks, since the side chat sends neither tool definitions nor the main thread's
 * thinking configuration and providers reject replaying those blocks without them.
 *
 * Tool activity survives as labelled text, so the model still sees what ran and
 * what it returned. Tool results fold into user turns and same-role turns merge,
 * keeping roles alternating for providers that require it.
 */
function toTextOnlyHistory(messages: Message[]): Message[] {
	const history: Message[] = [];

	const pushUser = (content: (TextContent | ImageContent)[]): void => {
		if (content.length === 0) return;
		const last = history.at(-1);
		if (last?.role === "user" && Array.isArray(last.content)) {
			last.content.push(...content);
			return;
		}
		history.push({ role: "user", content, timestamp: Date.now() });
	};

	for (const message of messages) {
		if (message.role === "user") {
			pushUser(
				typeof message.content === "string"
					? [{ type: "text", text: message.content }]
					: [...message.content],
			);
			continue;
		}

		if (message.role === "toolResult") {
			const label = message.isError ? "tool error" : "tool result";
			pushUser([{ type: "text", text: `[${label}: ${message.toolName}]` }, ...message.content]);
			continue;
		}

		const content: TextContent[] = [];
		for (const block of message.content) {
			if (block.type === "text") {
				if (block.text.trim().length > 0) content.push({ type: "text", text: block.text });
			} else if (block.type === "toolCall") {
				const args = JSON.stringify(block.arguments ?? {});
				content.push({ type: "text", text: `[tool call: ${block.name}(${args})]` });
			}
		}
		if (content.length === 0) continue;

		const last = history.at(-1);
		if (last?.role === "assistant") {
			last.content.push(...content);
			continue;
		}
		// The rewritten turn no longer matches the provider-side response it came from.
		history.push({
			...message,
			content,
			stopReason: "stop",
			errorMessage: undefined,
			responseId: undefined,
			deferred: undefined,
		});
	}

	return history;
}

export default function btwExtension(pi: ExtensionAPI) {
	pi.registerCommand("btw", {
		description: "Open a side-chat that doesn't add to the main thread (saves tokens)",
		handler: async (args, ctx) => {
			if (ctx.mode !== "tui") {
				ctx.ui.notify("/btw requires interactive mode", "error");
				return;
			}

			if (!ctx.model) {
				ctx.ui.notify("No model selected", "error");
				return;
			}

			// Freeze the main conversation context at entry.
			const branch = ctx.sessionManager.getBranch();
			const mainMessages = branch
				.filter((entry): entry is SessionEntry & { type: "message" } => entry.type === "message")
				.map((entry) => entry.message);
			const mainLlmMessages = toTextOnlyHistory(convertToLlm(mainMessages));
			const systemPrompt = ctx.getSystemPrompt();
			// Let the side chat reason at the same level as the main thread.
			const thinkingLevel = ctx.thinkingLevel;

			// Rendered transcript (role + text).
			const btwHistory: BtwMessage[] = [];
			// Side-chat turns fed back to the model on each follow-up. Assistant turns
			// are the exact AssistantMessage objects returned by complete().
			const btwLlmFollowups: Message[] = [];
			let isLoading = false;
			let loadingAbort: AbortController | null = null;

			const initialQuestion = args.trim();

			await ctx.ui.custom<void>((tui, theme, _kb, done) => {
				const mdTheme = getMarkdownTheme();
				const input = new Input();
				input.focused = true;
				let loader: Loader | null = null;

				const chatUI: Component & Focusable = {
					focused: true,

					handleInput(data: string) {
						// Esc: abort in-flight request, otherwise close.
						if (matchesKey(data, "escape")) {
							if (isLoading && loadingAbort) {
								loadingAbort.abort();
								isLoading = false;
								loadingAbort = null;
								if (loader) {
									loader.stop();
									loader = null;
								}
								tui.requestRender();
							} else {
								done();
							}
							return;
						}

						input.handleInput(data);
						tui.requestRender();
					},

					render(width: number): string[] {
						const lines: string[] = [];

						const headerText =
							theme.fg("accent", theme.bold(" btw ")) + theme.fg("dim", "side chat (Esc to close)");
						const bdr = theme.fg("border", "─".repeat(width));
						lines.push(bdr);
						lines.push(truncateToWidth(headerText, width));
						lines.push(bdr);

						for (const msg of btwHistory) {
							if (msg.role === "user") {
								lines.push("");
								const label = theme.fg("accent", theme.bold("you: "));
								const wrapped = wrapTextWithAnsi(label + msg.text, width - 2);
								for (const wl of wrapped) {
									lines.push(truncateToWidth(` ${wl}`, width));
								}
							} else {
								lines.push("");
								const md = new Markdown(msg.text, 1, 0, mdTheme);
								lines.push(...md.render(width));
							}
						}

						if (isLoading && loader) {
							lines.push(...loader.render(width));
						}

						lines.push("");
						lines.push(bdr);
						lines.push(...input.render(width));

						return lines;
					},

					invalidate() {},
				};

				input.onSubmit = (value: string) => {
					const question = value.trim();
					if (!question || isLoading) return;

					btwHistory.push({ role: "user", text: question });
					const userMessage: UserMessage = {
						role: "user",
						content: [{ type: "text", text: question }],
						timestamp: Date.now(),
					};
					btwLlmFollowups.push(userMessage);
					input.setValue("");
					isLoading = true;
					loader = new Loader(
						tui,
						(s) => theme.fg("accent", s),
						(s) => theme.fg("muted", s),
						"Working...",
					);
					tui.requestRender();

					loadingAbort = new AbortController();
					const signal = loadingAbort.signal;

					// An unanswered turn must not stay in the LLM history: providers that
					// enforce alternating roles reject a trailing user message.
					const dropPendingUserTurn = () => {
						const index = btwLlmFollowups.indexOf(userMessage);
						if (index !== -1) btwLlmFollowups.splice(index);
					};

					const doComplete = async () => {
						// modelRegistry.complete() resolves provider auth itself, so this works for
						// providers without an API key (e.g. Bedrock SigV4) as well as keyed ones.
						const response = await ctx.modelRegistry.complete(
							ctx.model!,
							{
								systemPrompt,
								messages: [...mainLlmMessages, ...btwLlmFollowups],
							},
							{ signal, reasoning: thinkingLevel },
						);

						if (response.stopReason === "aborted") {
							dropPendingUserTurn();
							return;
						}
						// complete() reports failures on the returned message instead of throwing.
						if (response.stopReason === "error") {
							throw new Error(response.errorMessage ?? `Request to ${response.provider} failed`);
						}

						const answer = response.content
							.filter((c): c is { type: "text"; text: string } => c.type === "text")
							.map((c) => c.text)
							.join("\n")
							.trim();

						btwLlmFollowups.push(response);
						btwHistory.push({
							role: "assistant",
							text: answer || `_(no text content, stop reason: ${response.stopReason})_`,
						});
					};

					doComplete()
						.catch((err: unknown) => {
							dropPendingUserTurn();
							if (signal.aborted) return;
							const message = err instanceof Error ? err.message : String(err);
							btwHistory.push({ role: "assistant", text: `Error: ${message}` });
						})
						.finally(() => {
							isLoading = false;
							loadingAbort = null;
							if (loader) {
								loader.stop();
								loader = null;
							}
							tui.requestRender();
						});
				};

				if (initialQuestion) {
					input.setValue(initialQuestion);
					input.onSubmit(initialQuestion);
				}

				return chatUI;
			});

			// Nothing is written back to the main session.
		},
	});
}
