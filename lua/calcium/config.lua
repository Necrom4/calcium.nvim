local M = {}

M.defaults = {
	notifications = true,
	default_mode = "append",
	scratchpad = {
		border = "rounded",
		virtual_text = {
			format = " = %s",
			highlight_group = "Comment",
		},
		result_variable = "ans",
	},
}

M.options = {}

function M.setup(opts)
	opts = opts or {}
	M.options = vim.tbl_deep_extend("force", M.defaults, opts)
end

return M
