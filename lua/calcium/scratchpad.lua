local M = {}

local config = require("calcium.config")

-- Centralized state
local state = {
	buf = nil,
	win = nil,
	ns = vim.api.nvim_create_namespace("CalciumGhost"),
}

local function is_valid(win)
	return win and vim.api.nvim_win_is_valid(win)
end

function M.close_scratchpad()
	if is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
	end
	state.win = nil
	state.buf = nil
end

local function setup_window()
	local buf = vim.api.nvim_create_buf(false, true)

	-- Buffer & Window options
	local b_opts = { buftype = "nofile", bufhidden = "wipe", swapfile = false, filetype = "calcium" }
	local w_opts = { wrap = false, cursorline = true, number = true, relativenumber = false }

	for opt, val in pairs(b_opts) do
		vim.bo[buf][opt] = val
	end

	local width, height = 80, 25
	local ui = vim.api.nvim_list_uis()[1]

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((ui.height - height) / 2),
		col = math.floor((ui.width - width) / 2),
		border = config.options.scratchpad.border or "single",
		style = "minimal",
		title = " Calcium Scratchpad ",
		title_pos = "center",
	})

	for opt, val in pairs(w_opts) do
		vim.wo[win][opt] = val
	end
	return buf, win
end

-- Helper to render virtual text results
local function render_result(line_idx, text, col)
	vim.api.nvim_buf_set_extmark(state.buf, state.ns, line_idx, col, {
		virt_text = { { "  = " .. text, "Comment" } },
		virt_text_pos = "inline",
		hl_mode = "combine",
	})
end

function M.evaluate_scratchpad()
	if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
		return
	end

	local calculator = require("calcium.calculator")
	local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)

	vim.api.nvim_buf_clear_namespace(state.buf, state.ns, 0, -1)

	local variables = calculator.extract_variables(lines)

	for i, line in ipairs(lines) do
		if line ~= "" then
			local success, result = calculator.evaluate_expression(line, variables)
			if success then
				render_result(i - 1, calculator.format_result(result), #line)
			end
		end
	end
end

function M.create_floating_calculator()
	if is_valid(state.win) then
		M.close_scratchpad()
		return
	end

	state.buf, state.win = setup_window()

	-- Keymaps
	local map_opts = { buffer = state.buf, silent = true }
	vim.keymap.set("n", "q", M.close_scratchpad, map_opts)
	vim.keymap.set("n", "<C-l>", function()
		vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, {})
		vim.api.nvim_buf_clear_namespace(state.buf, state.ns, 0, -1)
	end, map_opts)

	-- Autocmds
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = vim.api.nvim_create_augroup("CalciumFloating", { clear = true }),
		buffer = state.buf,
		callback = M.evaluate_scratchpad,
	})

	vim.cmd("startinsert!")
end

return M
