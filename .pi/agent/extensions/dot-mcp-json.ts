/**
 * Registers servers from `<cwd>/.mcp.json` (Claude Code format) with the built-in MCP support.
 * Built-in only reads `.pi/mcp.json`. Adapter-only keys are dropped; `directTools: true` maps to
 * `exposure: "direct"`.
 */

import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import type { ExtensionAPI, McpServerConfig } from "@earendil-works/pi-coding-agent";

const PASSTHROUGH = ["type", "command", "args", "env", "cwd", "url", "headers", "oauth", "exposure", "toolExposure", "enabled", "timeout"];

function toConfig(entry: Record<string, unknown>): McpServerConfig {
	const config: Record<string, unknown> = {};
	for (const key of PASSTHROUGH) if (entry[key] !== undefined) config[key] = entry[key];
	if (entry.directTools === true && config.exposure === undefined) config.exposure = "direct";
	return config as unknown as McpServerConfig;
}

export default function (pi: ExtensionAPI) {
	let registered: string[] = [];

	pi.on("session_start", async (_event, ctx) => {
		for (const name of registered) pi.unregisterMcpServer(name);
		registered = [];

		const path = join(ctx.cwd, ".mcp.json");
		if (!existsSync(path)) return;

		let servers: Record<string, Record<string, unknown>>;
		try {
			servers = JSON.parse(readFileSync(path, "utf8")).mcpServers ?? {};
		} catch (error) {
			ctx.ui.notify(`.mcp.json: ${(error as Error).message}`, "error");
			return;
		}

		for (const [name, entry] of Object.entries(servers)) {
			try {
				pi.registerMcpServer(name, toConfig(entry));
				registered.push(name);
			} catch (error) {
				ctx.ui.notify(`.mcp.json ${name}: ${(error as Error).message}`, "error");
			}
		}
	});
}
