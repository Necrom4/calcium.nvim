local M = {}

-- Token types
local TOKEN_TYPES = {
	NUMBER = 1,
	OPERATOR = 2,
	FUNCTION = 3,
	PAREN = 4,
	WORD = 5,
	SEPARATOR = 6,
	WHITESPACE = 7,
	OTHER = 8,
}

-- Math functions from calculator.lua mfl
local MATH_FUNCTIONS = {
	abs = true,
	acos = true,
	asin = true,
	atan = true,
	atan2 = true,
	ceil = true,
	cos = true,
	cosh = true,
	deg = true,
	exp = true,
	floor = true,
	fmod = true,
	frexp = true,
	huge = true,
	ldexp = true,
	log = true,
	log10 = true,
	max = true,
	min = true,
	modf = true,
	pi = true,
	pow = true,
	rad = true,
	random = true,
	randomseed = true,
	sin = true,
	sinh = true,
	sqrt = true,
	tan = true,
	tanh = true,
	avg = true,
	clamp = true,
	fact = true,
	fib = true,
	gcd = true,
	lcm = true,
	median = true,
	range = true,
	round = true,
	sign = true,
	trunc = true,
}

local function is_math_function(name)
	return MATH_FUNCTIONS[name] ~= nil
end

-- Create a token helper to reduce repetition
local function make_token(type, value, pos)
	return {
		type = type,
		value = value,
		start_col = pos,
		end_col = pos + #value - 1,
		is_variable = false,
	}
end

local function tokenize_line(line, known_variables)
	local tokens = {}
	local pos = 1

	-- Pattern list: each entry is {pattern, token_type, optional_handler}
	local patterns = {
		-- Numbers (in order of specificity)
		{ "^(%d+%.?%d*[eE][%+%-]?%d+)", TOKEN_TYPES.NUMBER },
		{ "^(%d+%.%d+)", TOKEN_TYPES.NUMBER },
		{ "^(%d+)", TOKEN_TYPES.NUMBER },
		-- Multi-char operators
		{ "^(==)", TOKEN_TYPES.OPERATOR },
		{ "^(~=)", TOKEN_TYPES.OPERATOR },
		{ "^(>=)", TOKEN_TYPES.OPERATOR },
		{ "^(<=)", TOKEN_TYPES.OPERATOR },
		{ "^(=)",  TOKEN_TYPES.OPERATOR },
		-- Single-char operators
		{ "^([%+%-%*/%%%^<>])", TOKEN_TYPES.OPERATOR },
		-- Parentheses
		{ "^([%(%)%[%]])", TOKEN_TYPES.PAREN },
		-- Separator
		{ "^(,)", TOKEN_TYPES.SEPARATOR },
		-- Whitespace
		{ "^(%s+)", TOKEN_TYPES.WHITESPACE },
		-- Words (identifiers)
		{
			"^([%a_][%w_]*)",
			TOKEN_TYPES.WORD,
			function(match)
				if is_math_function(match) then
					return TOKEN_TYPES.FUNCTION, false
				elseif known_variables and known_variables[match] then
					return TOKEN_TYPES.WORD, true
				end
				return TOKEN_TYPES.WORD, false
			end,
		},
		-- Other characters
		{ "^(.)", TOKEN_TYPES.OTHER },
	}

	while pos <= #line do
		local matched = false

		for _, pattern_info in ipairs(patterns) do
			local match = line:sub(pos):match(pattern_info[1])
			if match then
				local token_type = pattern_info[2]
				local is_var = false

				-- Call optional handler for special cases
				if pattern_info[3] then
					token_type, is_var = pattern_info[3](match)
				end

				local token = make_token(token_type, match, pos)
				token.is_variable = is_var
				table.insert(tokens, token)

				pos = pos + #match
				matched = true
				break
			end
		end

		if not matched then
			pos = pos + 1 -- Safety net (shouldn't happen)
		end
	end

	return tokens
end

-- Calculate confidence score for expression tokens
local function calculate_confidence(expr_tokens)
	local score = 0
	local has_operator = false
	local has_function = false
	local prose_word_count = 0

	for _, token in ipairs(expr_tokens) do
		if token.type == TOKEN_TYPES.OPERATOR then
			score = score + 3
			has_operator = true
		elseif token.type == TOKEN_TYPES.FUNCTION then
			score = score + 5
			has_function = true
		elseif token.type == TOKEN_TYPES.NUMBER then
			score = score + 1
		elseif token.type == TOKEN_TYPES.WORD then
			if token.is_variable then
				score = score + 2
			else
				prose_word_count = prose_word_count + 1
				score = score - 2
			end
		end
	end

	-- Require operator or function for good confidence
	if not (has_operator or has_function) then
		score = score - 5
	end

	-- Penalize multiple prose words
	if prose_word_count > 1 then
		score = score - prose_word_count * 3
	end

	return score
end

local function scan_forward_for_expression(tokens, start_idx, line)
	local expr_tokens = {}
	local paren_depth = 0
	local idx = start_idx
	local max_scan = 100
	local prev_token = nil

	while idx <= #tokens and idx - start_idx < max_scan do
		local token = tokens[idx]

		if token.type == TOKEN_TYPES.PAREN then
			local is_open = (token.value == "(" or token.value == "[")
			paren_depth = paren_depth + (is_open and 1 or -1)

			if paren_depth < 0 then
				break
			end
		end

		if paren_depth == 0 then
			if
				token.type == TOKEN_TYPES.OPERATOR
				and token.value == "-"
				and prev_token
				and prev_token.type == TOKEN_TYPES.OPERATOR
				and prev_token.value == "-"
			then
				table.remove(expr_tokens)
				break
			end

			if paren_depth == 0 then
				if
					(token.type == TOKEN_TYPES.OPERATOR and token.value == "=")
					or token.type == TOKEN_TYPES.SEPARATOR
					or token.type == TOKEN_TYPES.OTHER
					or (
						token.type == TOKEN_TYPES.WORD
						and not token.is_variable
						and not is_math_function(token.value)
						and #expr_tokens > 0
					)
				then
					break
				end
			end
		end

		if token.type ~= TOKEN_TYPES.WHITESPACE then
			table.insert(expr_tokens, token)
		end

		prev_token = token
		idx = idx + 1
	end

	if #expr_tokens == 0 then
		return nil
	end

	local start_col = expr_tokens[1].start_col
	local end_col = expr_tokens[#expr_tokens].end_col

	return {
		tokens = expr_tokens,
		text = line:sub(start_col, end_col),
		start_col = start_col,
		end_col = end_col,
		confidence = calculate_confidence(expr_tokens),
	}
end

local function find_expression_boundaries(tokens, line)
	local expressions = {}
	local covered_ranges = {}

	for i = 1, #tokens do
		local token = tokens[i]

		-- Check if this token is already part of an existing expression
		local is_covered = false
		for _, range in ipairs(covered_ranges) do
			if token.start_col >= range.start_col and token.start_col <= range.end_col then
				is_covered = true
				break
			end
		end

		if is_covered then
			goto continue
		end

		if token.is_variable then
			local next_idx = i + 1
			while next_idx <= #tokens and tokens[next_idx].type == TOKEN_TYPES.WHITESPACE do
				next_idx = next_idx + 1
			end
			if
				next_idx <= #tokens
				and tokens[next_idx].type == TOKEN_TYPES.OPERATOR
				and tokens[next_idx].value == "="
			then
				goto continue
			end
		end

		if not (token.type == TOKEN_TYPES.NUMBER or token.type == TOKEN_TYPES.FUNCTION or token.is_variable) then
			goto continue
		end

		local expr = scan_forward_for_expression(tokens, i, line)
		if expr then
			local is_duplicate = false
			for _, existing in ipairs(expressions) do
				if existing.start_col == expr.start_col and existing.end_col == expr.end_col then
					is_duplicate = true
					break
				end
			end

			if not is_duplicate then
				table.insert(expressions, expr)
				table.insert(covered_ranges, { start_col = expr.start_col, end_col = expr.end_col })
			end
		end

		::continue::
	end

	return expressions
end

local function select_closest_expression(expressions, cursor_col)
	if #expressions == 0 then
		return nil
	end

	local best = nil
	local min_distance = math.huge

	for _, expr in ipairs(expressions) do
		local distance

		if cursor_col >= expr.start_col and cursor_col <= expr.end_col then
			distance = 0 -- Cursor is inside
		else
			distance = math.min(math.abs(cursor_col - expr.start_col), math.abs(cursor_col - expr.end_col))
		end

		-- Prefer closer, then higher confidence, then leftmost
		if
			distance < min_distance
			or (distance == min_distance and expr.confidence > (best and best.confidence or 0))
			or (
				distance == min_distance
				and expr.confidence == (best and best.confidence or 0)
				and expr.start_col < (best and best.start_col or math.huge)
			)
		then
			min_distance = distance
			best = expr
		end
	end

	return best
end

-- Validate extracted expression text
local function validate_expression(expr_text)
	if expr_text:match("^%s*$") then
		return false
	end

	-- Check balanced parentheses
	local open = 0
	for c in expr_text:gmatch("[%(%)]") do
		open = open + (c == "(" and 1 or -1)
		if open < 0 then
			return false
		end
	end

	return open == 0
end

function M.extract_expression_at_cursor(line, cursor_col, buffer_lines)
	if not line or line == "" or cursor_col < 1 or cursor_col > #line then
		return nil
	end

	local success, result = pcall(function()
		local calculator = require("calcium.calculator")
		local known_variables = calculator.extract_variables(buffer_lines)
		local tokens = tokenize_line(line, known_variables)
		local expressions = find_expression_boundaries(tokens, line)

		if #expressions == 0 then
			return nil
		end

		local best = select_closest_expression(expressions, cursor_col)

		if not best or best.confidence < 5 or not validate_expression(best.text) then
			return nil
		end

		return {
			text = best.text,
			start_col = best.start_col,
			end_col = best.end_col,
		}
	end)

	return success and result or nil
end

return M
