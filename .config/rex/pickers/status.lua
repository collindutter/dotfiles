-- Prints every terminal that reports a program status, across all sessions.
-- Run with `rex do`; picker.sh formats the result for fzf.
local rank = { blocked = 1, error = 2, done = 3, working = 4, idle = 5 }
local items = {}

-- Untitled tabs are labelled "Window <id>"; show the terminal's title instead,
-- as the tab bar does.
local function tab_name(session_id, block, label)
	if label and not label:match("^Window %x+$") then
		return (label:gsub("^%s+", ""))
	end
	local ok, t = pcall(rex.block.call, "com.superlogical.terminal", "title", {
		block_id = block.block_id,
		session_id = session_id,
	})
	return ok and t and t.title or label or ""
end
for _, s in ipairs(rex.call("session.list").sessions or {}) do
	rex.call("session.attach", { session_id = s.session_id })
	local tabs = {}
	for _, w in ipairs((rex.call("session.view", { session_id = s.session_id }) or {}).windows or {}) do
		tabs[w.window_id] = w.label
	end
	for _, b in ipairs((rex.call("session.list_blocks", { session_id = s.session_id }) or {}).blocks or {}) do
		if b.creator_name == "com.superlogical.terminal" and b.placement == "placed" then
			local ok, status = pcall(rex.block.call, "com.superlogical.terminal", "program_status", {
				block_id = b.block_id,
				session_id = s.session_id,
			})
			for _, r in ipairs(ok and status and status.records or {}) do
				if r.id == nil and rank[r.state] then
					items[#items + 1] = {
						rank = rank[r.state],
						state = r.state,
						app = r.effective_app or "",
						msg = r.msg or r.title or "",
						session = s.label or "",
						tab = tab_name(s.session_id, b, tabs[b.window_id]),
						session_id = s.session_id,
						window_id = b.window_id,
						block_id = b.block_id,
						updated_at = r.updated_at or "",
					}
				end
			end
		end
	end
end
-- Most urgent first, then most recent. updated_at is ISO 8601 in one zone.
table.sort(items, function(x, y)
	if x.rank ~= y.rank then
		return x.rank < y.rank
	end
	return x.updated_at > y.updated_at
end)
return items
