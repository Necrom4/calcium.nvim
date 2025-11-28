local M = {}

function M.notify(msg, level, enabled, opts)
	if not enabled then
		return
	end

	opts = opts or {}
	opts.title = opts.title or "Calcium"
	opts.icon = opts.icon or ""

	vim.notify(msg, level or vim.log.levels.INFO, opts)
end

return M
