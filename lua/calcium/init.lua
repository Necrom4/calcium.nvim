local M = {}
local calculator = require("calcium.calculator")
local config = require("calcium.config")
local utils = require("calcium.utils")

function M.setup(opts)
	config.setup(opts)
end

local function handle_calculation(expr, buffer_lines)
	expr = utils.trim(expr)

	if expr == "" then
		return nil
	end

	local success, result = calculator.evaluate(expr, buffer_lines)

	if not success then
		return false, result
	end

	return true, calculator.format_result(result)
end

function M.calculate(mode, visual)
	mode = mode or "append"
	visual = visual or false

	local expr
	local start_line, start_col, end_line, end_col

	if visual then
		start_line, start_col = unpack(vim.api.nvim_buf_get_mark(0, "<"))
		end_line, end_col = unpack(vim.api.nvim_buf_get_mark(0, ">"))

		local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

		local end_line_content = lines[#lines] or ""
		end_col = math.min(end_col, #end_line_content - 1)

		if #lines == 1 then
			expr = string.sub(lines[1], start_col + 1, end_col + 1)
		else
			lines[1] = string.sub(lines[1], start_col + 1)
			lines[#lines] = string.sub(lines[#lines], 1, end_col + 1)
			expr = table.concat(lines, "\n")
		end
	else
		-- Use current line
		start_line = vim.api.nvim_win_get_cursor(0)[1]
		local line = vim.api.nvim_get_current_line()
		expr = line
		start_col = 0
		end_line = start_line
		end_col = #line - 1
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local buffer_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	local success, result = handle_calculation(expr, buffer_lines)
	if success == nil then
		utils.notify("No expression found", vim.log.levels.WARN, true)
		return
	elseif success == false then
		utils.notify("Calculation error: " .. tostring(result), vim.log.levels.ERROR, true)
		return
	end

	-- success == true, result is formatted
	if mode == "replace" then
		if visual then
			vim.api.nvim_buf_set_text(0, start_line - 1, start_col, end_line - 1, end_col + 1, { result })
		else
			local indentation = vim.api.nvim_get_current_line():match("^(%s+)") or ""
			vim.api.nvim_set_current_line(indentation .. result)
		end
	else
		local append_text = " = " .. result

		if visual then
			vim.api.nvim_buf_set_text(0, end_line - 1, end_col + 1, end_line - 1, end_col + 1, { append_text })
		else
			local current_line = vim.api.nvim_get_current_line()
			vim.api.nvim_set_current_line(current_line .. append_text)
		end
	end

	utils.notify("Result: " .. result, vim.log.levels.INFO, config.options.notifications)
end

function M.calculate_cmdline(expr)
	local bufnr = vim.api.nvim_get_current_buf()
	local buffer_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	local success, result = handle_calculation(expr, buffer_lines)
	if success == nil then
		utils.notify("No expression provided", vim.log.levels.WARN, true)
		return
	elseif success == false then
		utils.notify("Calculation error: " .. tostring(result), vim.log.levels.ERROR, true)
		return
	end

	utils.notify("Result: " .. result, vim.log.levels.INFO, true)
end

return M
