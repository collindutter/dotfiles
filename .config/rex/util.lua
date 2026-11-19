local M = {}

-- Rex calls return nil and an error message on failure. Raise it instead.
function M.checked(result, err)
	if err ~= nil then
		error(err, 0)
	end
	return result
end

function M.view(session_id)
	return M.checked(rex.call("session.view", { session_id = session_id }))
end

-- The window, block view and layer of the caller's terminal, or nil.
function M.caller_block(ctx)
	if not (ctx.session_id and ctx.block_id) then
		return nil
	end
	for _, w in ipairs(M.view(ctx.session_id).windows or {}) do
		for _, layer in ipairs(w.layers or {}) do
			for _, b in ipairs(layer.blocks or {}) do
				if b.block_id == ctx.block_id then
					return w, b, layer
				end
			end
		end
	end
	return nil
end

return M
