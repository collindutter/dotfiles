/**
 * Registers servers from `<agent-dir>/mcp.local.json`, which has the same shape as `mcp.json`
 * but stays out of dotfiles. Use it for servers only one machine should load.
 */

import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { type ExtensionAPI, getAgentDir, type McpServerConfig } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	const path = join(getAgentDir(), "mcp.local.json");
	if (!existsSync(path)) return;

	let servers: Record<string, McpServerConfig>;
	let loadError: string | undefined;
	try {
		servers = JSON.parse(readFileSync(path, "utf8")).mcpServers ?? {};
	} catch (error) {
		servers = {};
		loadError = `mcp.local.json: ${(error as Error).message}`;
	}

	const errors = loadError ? [loadError] : [];
	for (const [name, config] of Object.entries(servers)) {
		try {
			pi.registerMcpServer(name, config);
		} catch (error) {
			errors.push(`mcp.local.json ${name}: ${(error as Error).message}`);
		}
	}

	pi.on("session_start", async (_event, ctx) => {
		for (const message of errors) ctx.ui.notify(message, "error");
	});
}
