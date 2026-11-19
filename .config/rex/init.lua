-- https://www.superlogical.com/rex/docs
local function bind(key, action, args)
	rex.bind("ctrl+a>" .. key, action, args)
end

local util = require("util")
local checked = util.checked

local function shell(ctx, command)
	local process = rex.block.call("com.superlogical.terminal", "process", {
		block_id = ctx.block_id,
	})
	local cwd = process and ((process.foreground and process.foreground.cwd) or (process.child and process.child.cwd))
	return rex.layout.block({
		flavor = "com.superlogical.terminal.shell",
		options = { cwd = cwd, command = command },
	})
end

local function popup(ctx, command)
	return checked(rex.session.new_layer({
		bounds = { 0.05, 0.05, 0.9, 0.9 },
		focus = true,
		layout = shell(ctx, command),
	}))
end

rex.action({
	name = "popup",
	title = "Command in Floating Layer",
	args = {
		type = "object",
		properties = { command = { type = "array", items = { type = "string" }, minItems = 1 } },
		required = { "command" },
		additionalProperties = false,
	},
	run = function(ctx, args)
		return popup(ctx, args.command)
	end,
})

rex.action({
	name = "urls",
	title = "Find URLs in Pane",
	run = function(ctx)
		return popup(ctx, { "fish", "-c", "rex capture --unwrap --block " .. ctx.block_id .. " | urls" })
	end,
})

-- tmux's swap-pane -U and -D: swap with the previous or next pane in layout
-- order, wrapping at the ends. pane.move is spatial and stops at edges.
rex.action({
	name = "pane_swap",
	title = "Swap Pane with Previous or Next",
	args = { direction = "string" },
	run = function(ctx, args)
		local step = ({ previous = -1, next = 1 })[args.direction]
			or error('direction must be "previous" or "next"', 0)
		local _, _, layer = util.caller_block(ctx)
		local blocks = layer and layer.blocks or {}
		if #blocks < 2 then
			return
		end
		for i, b in ipairs(blocks) do
			if b.block_id == ctx.block_id then
				local other = blocks[(i - 1 + step) % #blocks + 1]
				return checked(rex.session.swap_blocks({ block_id = b.block_id, other_block_id = other.block_id }))
			end
		end
	end,
})

require("worktrees")

bind("ctrl+a", "pane.send_key", { key = "ctrl+a" })
bind("c", "client.tab.new")
-- Rex spells shifted characters using their unshifted keys, so each shifted
-- binding notes the character it stands for.
bind("shift+\\", "pane.split", { direction = "right" }) -- |
bind("\\", "pane.split", { direction = "down" })
bind("r", "client.config.reload")
bind("m", "pane.zoom")
bind("g", "popup", { command = { "lazygit" } })
bind("u", "urls")
bind("w", "worktree")
bind("shift+a", "popup", { command = { "aven", "-A" } }) -- A

bind("n", "client.tab.next")
bind("p", "client.tab.previous")
bind("shift+[", "pane_swap", { direction = "previous" }) -- {
bind("shift+]", "pane_swap", { direction = "next" }) -- }
bind(",", "client.tab.rename")
bind("shift+4", "session.rename") -- $
bind("x", "pane.close")
bind("shift+7", "close_window") -- &, offers to remove a worktree
bind("o", "pane.focus_next")
for i = 1, 9 do
	bind(tostring(i), "client.tab.goto", { index = i })
end

bind("s", "session_pick")
bind("shift+o", "session_pick") -- O
bind("/", "client.find.open")
bind("[", "pane.copy_mode.enter")

-- Prefix navigation remains an escape hatch. Direct navigation lets Neovim
-- receive Ctrl+h/j/k/l, while other foreground programs move Rex panes.
local function nvim_foreground(ctx)
	local ok, process = pcall(rex.block.call, "com.superlogical.terminal", "process", {
		block_id = ctx.block_id,
	})
	if not ok or type(process) ~= "table" or type(process.foreground) ~= "table" then
		return nil
	end

	local function is_nvim(candidate)
		if type(candidate) ~= "table" then
			return false
		end
		return candidate.name == "nvim" or (type(candidate.path) == "string" and candidate.path:match("/nvim$") ~= nil)
	end

	if is_nvim(process.foreground) then
		return true
	end
	for _, ancestor in ipairs(process.ancestors or {}) do
		if is_nvim(ancestor) then
			return true
		end
	end
	return false
end

local function focus_direction(ctx, direction)
	local foreground_is_nvim = nvim_foreground(ctx)
	if foreground_is_nvim == nil or foreground_is_nvim then
		return false
	end
	local ok, result, err = pcall(rex.session.focus_direction, { direction = direction })
	return ok and err == nil and result ~= nil
end

for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	rex.bind("ctrl+" .. key, function(ctx)
		return focus_direction(ctx, direction)
	end)
	bind(key, "pane.focus", { direction = direction })
end
