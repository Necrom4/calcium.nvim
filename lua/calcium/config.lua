local M = {}

M.defaults = {
	notifications = true,
	default_mode = "append",
	scratchpad = {
		border = "rounded",
	},
}

M.options = {}

function M.setup(opts)
	opts = opts or {}
	M.options = vim.tbl_deep_extend("force", M.defaults, opts)
end

return M
