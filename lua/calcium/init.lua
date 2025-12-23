local M = {}
local calculator = require("calcium.calculator")
local config = require("calcium.config")
local utils = require("calcium.utils")
local scratchpad = require("calcium.scratchpad")

function M.setup(opts)
	config.setup(opts)
end

local function evaluate_expression(expr, buffer_lines)
	expr = utils.trim(expr)

	if expr == "" then
		return nil
	end

	local success, result = calculator.evaluate(expr, buffer_lines)
	return success and true or false, success and calculator.format_result(result) or result
end

local function apply_result_to_buffer(result, mode, visual, start_line, start_col, end_line, end_col)
	if mode == "replace" then
		if visual then
			vim.api.nvim_buf_set_text(0, start_line - 1, start_col, end_line - 1, end_col + 1, { result })
		else
			local current_line = vim.api.nvim_get_current_line()
			local is_whole_line = (start_col == 0 and end_col == #current_line - 1)
			if is_whole_line then
				local indent = current_line:match("^(%s+)") or ""
				vim.api.nvim_set_current_line(indent .. result)
			else
				vim.api.nvim_buf_set_text(0, start_line - 1, start_col, start_line - 1, end_col + 1, { result })
			end
		end
	else -- append mode
		local append_text = " = " .. result
		if visual then
			vim.api.nvim_buf_set_text(0, end_line - 1, end_col + 1, end_line - 1, end_col + 1, { append_text })
		else
			local current_line = vim.api.nvim_get_current_line()
			local is_whole_line = (start_col == 0 and end_col == #current_line - 1)
			if is_whole_line then
				vim.api.nvim_set_current_line(current_line .. append_text)
			else
				vim.api.nvim_buf_set_text(0, start_line - 1, end_col + 1, start_line - 1, end_col + 1, { append_text })
			end
		end
	end
end

local function extract_visual_selection()
	local start_line, start_col = unpack(vim.api.nvim_buf_get_mark(0, "<"))
	local end_line, end_col = unpack(vim.api.nvim_buf_get_mark(0, ">"))
	local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

	local end_line_content = lines[#lines] or ""
	end_col = math.min(end_col, #end_line_content - 1)

	local expr
	if #lines == 1 then
		expr = string.sub(lines[1], start_col + 1, end_col + 1)
	else
		lines[1] = string.sub(lines[1], start_col + 1)
		lines[#lines] = string.sub(lines[#lines], 1, end_col + 1)
		expr = table.concat(lines, "\n")
	end

	return expr, start_line, start_col, end_line, end_col
end

local function extract_normal_mode(buffer_lines)
	local start_line = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_get_current_line()
	local cursor_col = vim.api.nvim_win_get_cursor(0)[2]

	-- Try smart extraction
	local parser = require("calcium.parser")
	local extracted = parser.extract_expression_at_cursor(line, cursor_col + 1, buffer_lines)

	local expr, start_col, end_col
	if extracted and extracted.text ~= "" then
		expr = extracted.text
		start_col = extracted.start_col - 1
		end_col = extracted.end_col - 1
	else
		-- Fallback to whole line
		expr = line
		start_col = 0
		end_col = #line - 1
	end

	return expr, start_line, start_col, start_line, end_col
end

function M.calculate(mode, visual)
	mode = mode or "append"
	visual = visual or false

	local bufnr = vim.api.nvim_get_current_buf()
	local buffer_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	local expr, start_line, start_col, end_line, end_col
	if visual then
		expr, start_line, start_col, end_line, end_col = extract_visual_selection()
	else
		expr, start_line, start_col, end_line, end_col = extract_normal_mode(buffer_lines)
	end

	local success, result = evaluate_expression(expr, buffer_lines)

	if success == nil then
		utils.notify("No expression found", vim.log.levels.WARN, true)
		return
	elseif success == false then
		utils.notify("Calculation error: " .. tostring(result), vim.log.levels.ERROR, true)
		return
	end

	apply_result_to_buffer(result, mode, visual, start_line, start_col, end_line, end_col)
	utils.notify("Result: " .. result, vim.log.levels.INFO, config.options.notifications)
end

function M.calculate_cmdline(expr)
	local bufnr = vim.api.nvim_get_current_buf()
	local buffer_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	local success, result = evaluate_expression(expr, buffer_lines)

	if success == nil then
		utils.notify("No expression provided", vim.log.levels.WARN, true)
		return
	elseif success == false then
		utils.notify("Calculation error: " .. tostring(result), vim.log.levels.ERROR, true)
		return
	end

	utils.notify("Result: " .. result, vim.log.levels.INFO, true)
end

function M.scratchpad()
	scratchpad.create_scratchpad()
end

return M
