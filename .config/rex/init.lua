-- https://www.superlogical.com/rex/docs
local function bind(key, action, args)
	rex.bind("ctrl+a>" .. key, action, args)
end

local function checked(result, err)
	if err then
		error(err, 0)
	end
	return result
end

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
		return checked(rex.session.new_layer({
			bounds = { 0.05, 0.05, 0.9, 0.9 },
			focus = true,
			layout = shell(ctx, args.command),
		}))
	end,
})

-- Runs command in a login shell that stays open after the command exits.
local function worktree_pane(path, command)
	local sh = os.getenv("SHELL") or "/bin/zsh"
	return rex.layout.block({
		flavor = "com.superlogical.terminal.shell",
		options = { cwd = path, command = { sh, "-lic", command .. "; exec " .. sh .. " -l" } },
	})
end

-- Worktree windows in the current session. `wt switch` and `wt remove` from
-- the CLI open and close them through the hooks in ~/.config/worktrunk/config.toml.
require("rex-worktrunk").setup({
	target = "window",
	-- Nerd Font git-branch glyph, matching workmux's nerdfont window prefix.
	prefix = "\239\144\152 ",
	layout = function(_, path)
		return rex.layout.horizontal(0.5, worktree_pane(path, "nvim"), worktree_pane(path, "pi"))
	end,
})

bind("ctrl+a", "pane.send_key", { key = "ctrl+a" })
bind("c", "client.tab.new")
-- Rex spells shifted characters using their unshifted keys.
bind("shift+\\", "pane.split", { direction = "right" })
bind("\\", "pane.split", { direction = "down" })
bind("r", "client.config.reload")
bind("m", "pane.zoom")
bind("g", "popup", { command = { "lazygit" } })
local pickers = os.getenv("HOME") .. "/.config/rex/pickers/"
bind("shift+o", "popup", { command = { pickers .. "sesh.sh" } })
bind("shift+w", "popup", { command = { pickers .. "activity.sh" } })
bind("shift+a", "popup", { command = { "aven", "-A" } })

bind("n", "client.tab.next")
bind("p", "client.tab.previous")
bind("shift+[", "pane.move", { direction = "left" })
bind("shift+]", "pane.move", { direction = "right" })
bind(",", "client.tab.rename")
bind("shift+4", "session.rename")
bind("x", "pane.close")
bind("shift+7", "client.tab.close")
bind("o", "pane.focus_next")
for i = 1, 9 do
	bind(tostring(i), "client.tab.goto", { index = i })
end

bind("s", "session.switch")
bind("/", "client.find.open")

-- An arrow after the prefix enters resize mode. Arrows then resize until
-- Escape or Enter. Amount is percent of the split.
rex.mode("resize", { exclusive = true })
rex.bind("resize/enter", "client.mode.exit")
for _, direction in ipairs({ "left", "down", "up", "right" }) do
	bind(direction, "client.mode.enter", { name = "resize" })
	rex.bind("resize/" .. direction, "pane.resize", { direction = direction, amount = 5 })
end
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
