if vim.g.loaded_calcium then
	return
end
vim.g.loaded_calcium = 1

vim.api.nvim_create_user_command("Calcium", function(opts)
	local mode = "append"
	local visual = false

	if opts.args and opts.args ~= "" then
		local args = vim.split(opts.args, "%s+", { trimempty = true })

		if args[1] == "append" or args[1] == "a" then
			mode = "append"
		elseif args[1] == "replace" or args[1] == "r" then
			mode = "replace"
		elseif args[1] == "scratchpad" or not args[1] then
			require("calcium").scratchpad()
			return
		else
			require("calcium").calculate_cmdline(opts.args)
			return
		end
	end

	if opts.range > 0 then
		visual = true
	end

	require("calcium").calculate(mode, visual)
end, {
	nargs = "?",
	range = true,
	complete = function(_, cmdline, _)
		if cmdline:find("%s+%a") then
			return {}
		end

		return { "append", "replace", "scratchpad" }
	end,
	desc = "Calculate",
})
