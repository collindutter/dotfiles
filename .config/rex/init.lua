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
	name = "new_tab_here",
	title = "New Tab in Current Directory",
	run = function(ctx)
		return checked(rex.session.new_window({ layout = shell(ctx) }))
	end,
})

rex.action({
	name = "split_here",
	title = "Split in Current Directory",
	args = {
		type = "object",
		properties = { direction = { type = "string", enum = { "horizontal", "vertical" } } },
		required = { "direction" },
		additionalProperties = false,
	},
	run = function(ctx, args)
		return checked(rex.session.new_split({
			anchor_id = ctx.block_id,
			direction = args.direction,
			side = "after",
			focus = true,
			layout = shell(ctx),
		}))
	end,
})

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

rex.action({
	name = "swap_pane",
	title = "Swap Pane",
	args = {
		type = "object",
		properties = { offset = { type = "integer", enum = { -1, 1 } } },
		required = { "offset" },
		additionalProperties = false,
	},
	run = function(ctx, args)
		local view = checked(rex.session.view({}))
		for _, window in ipairs(view.windows or {}) do
			for _, layer in ipairs(window.layers or {}) do
				local blocks = layer.blocks or {}
				for i, block in ipairs(blocks) do
					if block.block_id == ctx.block_id then
						if #blocks < 2 then
							return
						end
						local target = blocks[(i - 1 + args.offset) % #blocks + 1]
						return checked(rex.session.swap_blocks({
							block_id = ctx.block_id,
							other_block_id = target.block_id,
						}))
					end
				end
			end
		end
	end,
})

bind("ctrl+a", "pane.send_key", { key = "ctrl+a" })
bind("c", "new_tab_here")
-- Rex spells shifted characters using their unshifted keys.
bind("shift+\\", "split_here", { direction = "horizontal" })
bind("\\", "split_here", { direction = "vertical" })
bind("r", "client.config.reload")
bind("m", "pane.zoom")
bind("z", "pane.zoom")
bind("g", "popup", { command = { "lazygit" } })
bind("shift+d", "popup", { command = { "workmux", "dashboard" } })
bind("shift+a", "popup", { command = { "aven", "-A" } })

bind("n", "client.tab.next")
bind("p", "client.tab.previous")
bind("shift+[", "swap_pane", { offset = -1 })
bind("shift+]", "swap_pane", { offset = 1 })
bind(",", "client.tab.rename")
bind("shift+4", "session.rename")
bind("x", "pane.close")
bind("shift+7", "client.tab.close")
bind("o", "pane.focus_next")
for i = 1, 9 do
	bind(tostring(i), "client.tab.goto", { index = i })
end

bind("s", "session.switch")
bind("shift+o", "session.switch")
-- Native palette replaces the tmux window pickers, not a window-only list.
bind("w", "client.palette.toggle")
bind("shift+w", "client.palette.toggle")
-- Native Find replaces reverse copy-mode search.
bind("/", "client.find.open")

-- Amount is percent of the split, not tmux's cell count.
for _, direction in ipairs({ "left", "down", "up", "right" }) do
	bind(direction, "pane.resize", { direction = direction, amount = 5 })
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
