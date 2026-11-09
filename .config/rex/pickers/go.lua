-- Shows a session in the Rex app, optionally at a window and block.
--   rex do go.lua session_id=... [window_id=...] [block_id=...]
local a = rex.args
rex.call("session.attach", { session_id = a.session_id })
if a.block_id then
	local _, err = rex.call("session.focus_block", { session_id = a.session_id, block_id = a.block_id })
	if err then
		error(err, 0)
	end
end
local apps = rex.call("client.list", { kinds = { "app" } })
for _, c in ipairs(apps and apps.clients or {}) do
	rex.call("client.perform", {
		client_id = c.client_id,
		action = "session.select",
		args = { session_id = a.session_id, window_id = a.window_id },
	})
end
