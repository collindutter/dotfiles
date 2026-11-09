-- Opens a directory as a window or session with Neovim and Pi side by side.
-- worktrunk's hooks in ~/.config/worktrunk/config.toml open and close worktree
-- windows:
--   rex do open_dir path=/path/to/repo.feature [target=session]
--   rex do close_dir path=/path/to/repo.feature
-- From the CLI, the app shows the result only with Remote Control on
-- (Rex → Settings → Rex Server).

local TERMINAL = "com.superlogical.terminal"
-- Nerd Font git-branch glyph before window labels.
local WINDOW_PREFIX = "\239\144\152 "

local function checked(result, err)
	if err ~= nil then
		error(err, 0)
	end
	return result
end

local function basename(path)
	return (path:gsub("/+$", ""):match("([^/]+)$"))
end

-- A login shell running command that stays open after the command exits.
local function pane(path, command)
	local sh = os.getenv("SHELL") or "/bin/zsh"
	return rex.layout.block({
		flavor = TERMINAL .. ".shell",
		options = { cwd = path, command = { sh, "-lic", command .. "; exec " .. sh .. " -l" } },
	})
end

local function layout(path)
	return rex.layout.horizontal(0.5, pane(path, "nvim"), pane(path, "pi"))
end

local function block_cwd(block_id)
	local ok, p = pcall(rex.block.call, TERMINAL, "process", { block_id = block_id })
	if not ok or type(p) ~= "table" then
		return nil
	end
	return (p.foreground and p.foreground.cwd) or (p.child and p.child.cwd)
end

local function windows(session_id)
	return checked(rex.call("session.view", { session_id = session_id })).windows or {}
end

local function find_window_by_label(session_id, label)
	for _, w in ipairs(windows(session_id)) do
		if w.label == label then
			return w.window_id
		end
	end
	return nil
end

-- A window with a tiled terminal in path or below it. This finds windows opened
-- by hand, such as the main checkout that `wt switch ^` returns to.
local function find_window_by_cwd(session_id, path)
	for _, w in ipairs(windows(session_id)) do
		for _, layer in ipairs(w.layers or {}) do
			for _, b in ipairs(layer.kind == "tiled" and layer.blocks or {}) do
				local cwd = b.creator_name == TERMINAL and block_cwd(b.block_id)
				if cwd and (cwd == path or cwd:sub(1, #path + 1) == path .. "/") then
					return w.window_id
				end
			end
		end
	end
	return nil
end

local function open_window(ctx, path)
	local session_id = ctx.session_id or error("no session to open a window in", 0)
	local label = WINDOW_PREFIX .. basename(path)
	local window_id = find_window_by_label(session_id, label) or find_window_by_cwd(session_id, path)
	if window_id then
		checked(rex.call("session.focus_window", { session_id = session_id, window_id = window_id }))
	else
		window_id = checked(rex.call("session.new_window", {
			session_id = session_id,
			window_label = label,
			layout = layout(path),
		})).window_id
	end
	return session_id, window_id
end

local function open_session(path)
	local label = basename(path)
	for _, s in ipairs(checked(rex.call("session.list")).sessions or {}) do
		if s.label == label then
			return s.session_id
		end
	end
	return checked(rex.call("session.create", {
		label = label,
		initial_windows = { { layout = layout(path) } },
	})).session_id
end

-- Ask the Rex app to show a session, optionally at a window.
local function show(ctx, session_id, window_id)
	local args = { session_id = session_id, window_id = window_id }
	if ctx.origin == "key" or ctx.origin == "palette" then
		rex.client.queue("session.select", args)
		return
	end
	local apps = rex.call("client.list", { kinds = { "app" }, session_id = ctx.session_id })
	if apps == nil or #(apps.clients or {}) == 0 then
		apps = rex.call("client.list", { kinds = { "app" } })
	end
	local last_err = "no Rex app is connected"
	for _, c in ipairs(apps and apps.clients or {}) do
		local _, err = rex.call("client.perform", {
			client_id = c.client_id,
			action = "session.select",
			args = args,
			origin = ctx.origin,
		})
		if err == nil then
			return
		end
		last_err = err
	end
	error("opened, but the app would not show it: " .. tostring(last_err), 0)
end

rex.action({
	name = "open_dir",
	title = "Open Directory",
	description = "Show a directory as a window in this session, or as its own session, creating it if needed.",
	args = { path = "string", target = "string?" },
	run = function(ctx, args)
		local path = args.path
		if not rex.exec({ "test", "-d", path }).ok then
			error("not a directory: " .. path, 0)
		end
		local target = args.target or "window"
		local session_id, window_id
		if target == "window" then
			session_id, window_id = open_window(ctx, path)
		elseif target == "session" then
			session_id = open_session(path)
		else
			error('target must be "window" or "session"', 0)
		end
		show(ctx, session_id, window_id)
		return { session_id = session_id, window_id = window_id }
	end,
})

rex.action({
	name = "close_dir",
	title = "Close Directory Window",
	description = "Close the window open_dir made for a directory in this session.",
	args = { path = "string" },
	run = function(ctx, args)
		local window_id = ctx.session_id and find_window_by_label(ctx.session_id, WINDOW_PREFIX .. basename(args.path))
		if window_id then
			checked(rex.call("session.close_window", { session_id = ctx.session_id, window_id = window_id }))
		end
		return { closed = window_id ~= nil }
	end,
})
