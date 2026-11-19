-- Worktree and session pickers. workmux creates and removes worktrees and
-- their windows. These actions run it in the background and show the window
-- themselves, since an action can switch the app without Remote Control.

-- workmux's window_prefix when nerdfont is on: a git-branch glyph and a space.
local WINDOW_PREFIX = "\239\144\152 "

local util = require("util")
local checked, view, caller_block = util.checked, util.view, util.caller_block

local function tilde(path)
	local home = os.getenv("HOME")
	return home and path:sub(1, #home) == home and "~" .. path:sub(#home + 1) or path
end

local function find_window(session_id, label)
	for _, w in ipairs(view(session_id).windows or {}) do
		if w.label == label then
			return w.window_id
		end
	end
	return nil
end

-- Ask the app to show a window. It shows its own selection, not the server's
-- active window. An app that ran the action takes queued actions; from the CLI,
-- it accepts them only with Remote Control on.
local function show(ctx, args)
	if ctx.origin == "key" or ctx.origin == "palette" then
		rex.client.queue("session.select", args)
		return
	end
	local _, b = caller_block(ctx)
	local client_id = b and b.owner
	if not client_id then
		local r = checked(rex.call("target.resolve", { kinds = { "client" }, queries = { "" } })).results[1]
		client_id = r.client_id or error("no app to show it in: " .. tostring(r.reason or r.status), 0)
	end
	checked(rex.call("client.perform", {
		client_id = client_id,
		action = "session.select",
		args = args,
		origin = ctx.origin,
	}))
end

local function focused_cwd(ctx)
	local process = ctx.block_id
		and rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
	return process and ((process.foreground and process.foreground.cwd) or (process.child and process.child.cwd))
		or error("focus a terminal inside a git repository", 0)
end

-- A server started by launchd has only the system PATH, so take it from the
-- login shell, where tools like workmux are installed.
local function login_path()
	local r = rex.exec({ os.getenv("SHELL") or "/bin/sh", "-l", "-c", 'printf %s "$PATH"' }, { timeout = 10 })
	return r and r.ok and r.stdout ~= "" and r.stdout or error("could not read PATH from the login shell", 0)
end

local function run(argv, opts)
	local r = checked(rex.exec(argv, opts))
	if not r.ok then
		error(table.concat(argv, " ") .. " failed: " .. (r.stderr ~= "" and r.stderr or r.stdout), 0)
	end
	return r.stdout
end

local function git(cwd, path, argv)
	table.insert(argv, 1, "git")
	return run(argv, { cwd = cwd, env = { PATH = path }, timeout = 30 })
end

-- The server's socket and the directory of its executable, which is the rex
-- CLI. Rex puts that directory on PATH only in its own terminals.
local function server()
	local status = checked(rex.call("server.status"))
	local endpoint
	for _, l in ipairs(status.listeners or {}) do
		if l.primary then
			endpoint = l.endpoint
		end
	end
	local exe = run({ "ps", "-o", "comm=", "-p", tostring(status.pid) }, { timeout = 10 })
	return endpoint or error("Rex server reports no primary listener", 0), exe:match("^(.*)/[^/]*\n?$")
end

-- workmux finds the server, session and calling block in the environment a
-- Rex terminal gets, so give it the focused terminal's.
local function workmux(ctx, cwd, path, argv)
	table.insert(argv, 1, "workmux")
	local endpoint, bin_dir = server()
	local env = {
		PATH = path .. ":" .. bin_dir,
		REX_SERVER = endpoint,
		REX_SESSION = ctx.session_id,
		REX_BLOCK = ctx.block_id,
		NO_COLOR = "1",
	}
	return run(argv, { cwd = cwd, env = env, timeout = 300 })
end

local function worktrees(ctx, cwd, path)
	return rex.json.decode(workmux(ctx, cwd, path, { "list", "--json" }))
end

-- Worktrees first, then local branches without one, each by latest commit.
-- Each id is a branch name. Plain git, because listing every worktree's status
-- takes seconds in large repositories. Branches whose upstream is gone are
-- left out, and rows carry no commit subjects, since the palette's fuzzy
-- filter matches long text against almost anything typed.
local function worktree_items(cwd, path)
	local worktree_paths = {}
	local current
	for line in git(cwd, path, { "worktree", "list", "--porcelain" }):gmatch("[^\n]+") do
		local dir = line:match("^worktree (.+)$")
		if dir then
			current = dir
		end
		local branch = line:match("^branch refs/heads/(.+)$")
		if branch then
			worktree_paths[branch] = current
		end
	end

	local items, branches = {}, {}
	local refs = git(cwd, path, {
		"for-each-ref",
		"--sort=-committerdate",
		"--format=%(refname:short)%09%(upstream:track,nobracket)",
		"refs/heads",
	})
	for line in refs:gmatch("[^\n]+") do
		local branch, track = line:match("^([^\t]*)\t(.*)$")
		local dir = branch and worktree_paths[branch]
		if dir then
			table.insert(items, {
				id = branch,
				icon = "folder",
				subtitle = tilde(dir),
				detail = track ~= "" and track or nil,
			})
		elseif branch and track ~= "gone" then
			table.insert(branches, { id = branch, icon = "branch", detail = track ~= "" and track or nil })
		end
	end
	for _, item in ipairs(branches) do
		table.insert(items, item)
	end
	return items
end

-- Git refuses spaces in branch names, so typed words become one-name-like-this.
local function branch_name(text)
	return (text:match("^%s*(.-)%s*$"):gsub("%s+", "-"))
end

-- An id no branch can have, since git refuses spaces in branch names.
local NEW = "new worktree"

-- What to pass workmux add for a typed name: the name when it is a local
-- branch or a new one, or remote/name when only a remote has it, so the new
-- branch tracks it.
local function add_ref(cwd, path, name)
	local function first(pattern)
		return git(cwd, path, { "for-each-ref", "--count=1", "--format=%(refname:short)", pattern }):match("^%S+")
	end
	return first("refs/heads/" .. name) or first("refs/remotes/*/" .. name) or name
end

rex.action({
	name = "worktree",
	title = "Worktree: Switch or Create",
	description = "Pick a worktree or branch in the focused terminal's repository, or type a name to create one, and open it as a window.",
	run = function(ctx)
		local cwd = focused_cwd(ctx)
		local path = login_path()
		local items = worktree_items(cwd, path)
		table.insert(items, 1, { id = NEW, title = "New worktree…", icon = "plus" })
		local choice, why = rex.ui.pick({
			title = "Worktree",
			placeholder = "Filter worktrees and branches, or type a new branch",
			items = items,
			allow_other = true,
		})
		if choice == NEW then
			local text
			text, why = rex.ui.input({ title = "New worktree", placeholder = "branch-name", confirm = "Create worktree" })
			choice = text and { text = text }
		end
		if choice == nil then
			if why == "cancelled" then
				return
			end
			error("worktree picker: " .. why, 0)
		end

		local branch, ref = choice, choice
		if type(choice) == "table" then
			branch = branch_name(choice.text)
			if branch == "" then
				return
			end
			ref = add_ref(cwd, path, branch)
		end
		workmux(ctx, cwd, path, { "add", "--background", "--open-if-exists", ref })

		for _, w in ipairs(worktrees(ctx, cwd, path)) do
			if w.branch == branch then
				local window_id = find_window(ctx.session_id, WINDOW_PREFIX .. w.handle)
					or error("workmux opened no window for " .. w.handle, 0)
				show(ctx, { session_id = ctx.session_id, window_id = window_id })
				return { path = w.path, window_id = window_id }
			end
		end
		error("workmux has no worktree for " .. branch, 0)
	end,
})

rex.action({
	name = "session_pick",
	title = "Switch Session",
	description = "Pick a session and show its first window.",
	run = function(ctx)
		local items, first_window = {}, {}
		for _, s in ipairs(checked(rex.call("session.list")).sessions or {}) do
			local windows = view(s.session_id).windows or {}
			first_window[s.session_id] = windows[1] and windows[1].window_id
			table.insert(items, {
				id = s.session_id,
				title = s.label,
				icon = "terminal",
				detail = s.session_id == ctx.session_id and "current" or (#windows .. (#windows == 1 and " window" or " windows")),
			})
		end
		local session_id, why = rex.ui.pick({ title = "Session", placeholder = "Filter sessions", items = items })
		if session_id == nil then
			if why == "cancelled" then
				return
			end
			error("session picker: " .. why, 0)
		end
		show(ctx, { session_id = session_id, window_id = first_window[session_id] })
	end,
})

-- The workmux worktree whose window this is: the focused terminal's linked
-- worktree, when the window carries its label. Returns it and the login PATH.
local function window_worktree(ctx, window)
	if not (window and window.label and window.label:sub(1, #WINDOW_PREFIX) == WINDOW_PREFIX) then
		return nil
	end
	local path = login_path()
	local ok, cwd = pcall(focused_cwd, ctx)
	local r = ok and rex.exec({ "git", "rev-parse", "--show-toplevel" }, { cwd = cwd, env = { PATH = path } })
	local top = r and r.ok and r.stdout:match("^%s*(.-)%s*$")
	if not top then
		return nil
	end
	for _, w in ipairs(worktrees(ctx, top, path)) do
		if w.path == top and not w.is_main and window.label == WINDOW_PREFIX .. w.handle then
			return w, path
		end
	end
	return nil
end

local function close_tab(ctx, window)
	if ctx.origin == "key" or ctx.origin == "palette" then
		rex.client.queue("client.tab.close")
	elseif window then
		checked(rex.call("session.close_window", { session_id = ctx.session_id, window_id = window.window_id }))
	end
end

rex.action({
	name = "close_window",
	title = "Close Window",
	description = "Close the focused window. On a worktree's window, offer to remove the worktree with workmux as well.",
	run = function(ctx)
		local window = caller_block(ctx)
		local wt, path = window_worktree(ctx, window)
		if not wt then
			return close_tab(ctx, window)
		end

		local discard = wt.has_uncommitted_changes and " and discard uncommitted changes" or ""
		local choice, why = rex.ui.pick({
			title = "Close " .. wt.branch,
			items = {
				{ id = "close", title = "Close window", subtitle = "Keep the worktree", icon = "folder" },
				{ id = "keep", title = "Remove worktree" .. discard, subtitle = "Keep branch " .. wt.branch, icon = "branch" },
				{ id = "delete", title = "Remove worktree and branch" .. discard, subtitle = tilde(wt.path), icon = "branch" },
			},
		})
		if choice == nil then
			if why == "cancelled" then
				return
			end
			error("close window: " .. why, 0)
		end
		if choice == "close" then
			return close_tab(ctx, window)
		end

		-- workmux asks before discarding changes or an unmerged branch, and
		-- an action can't answer, so pass --force for what was just chosen.
		-- It closes the window itself.
		local argv = { "remove" }
		if choice == "keep" then
			table.insert(argv, "--keep-branch")
		end
		if choice == "delete" or wt.has_uncommitted_changes then
			table.insert(argv, "--force")
		end
		table.insert(argv, wt.handle)
		workmux(ctx, wt.path, path, argv)
	end,
})
