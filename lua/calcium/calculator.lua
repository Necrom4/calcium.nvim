local M = {}
local utils = require("calcium.utils")

function M.extract_variables(buffer_lines)
	local variables = {}

	local pattern = "^%s*([%w_]+)%s*=%s*(.+)$"

	for _, line in ipairs(buffer_lines) do
		local var_name, var_expr = line:match(pattern)
		if var_name and var_expr then
			-- Remove trailing comments
			var_expr = var_expr:gsub("%s*%-%-.*$", ""):gsub("%s*#.*$", "")
			var_expr = utils.trim(var_expr)

			local success, value = M.evaluate_expression(var_expr, variables)
			if success then
				variables[var_name] = value
			end
		end
	end

	return variables
end

function M.evaluate_expression(expr, variables)
	-- Replace scientific notation
	expr = expr:gsub("(%d+%.?%d*)e([%-%+]?%d+)", function(num, exp)
		return string.format("(%s * 10^%s)", num, exp)
	end)

	-- Replace variables with their values
	if variables then
		for var_name, var_value in pairs(variables) do
			local pattern = "%f[%w_]" .. var_name .. "%f[^%w_]"
			expr = expr:gsub(pattern, tostring(var_value))
		end
	end

	-- Mathematical Functions Library definition
	local mfl = {}

	for k, v in pairs(math) do
		mfl[k] = v
	end

	mfl.avg = function(...)
		local t = { ... }
		local sum = 0
		for _, v in ipairs(t) do
			sum = sum + v
		end
		return sum / #t
	end

	mfl.clamp = function(n, min, max)
		return math.max(min, math.min(max, n))
	end

	mfl.fact = function(n)
		n = math.floor(n)
		if n < 0 then
			return 0
		end
		local r = 1
		for i = 2, n do
			r = r * i
		end
		return r
	end

	mfl.fib = function(n)
		n = math.floor(n)
		if n < 0 then
			return 0
		end
		if n < 2 then
			return n
		end
		local a, b = 0, 1
		for _ = 2, n do
			a, b = b, a + b
		end
		return b
	end

	mfl.gcd = function(a, b)
		a, b = math.abs(a), math.abs(b)
		while b ~= 0 do
			a, b = b, a % b
		end
		return a
	end

	mfl.lcm = function(a, b)
		return math.abs(a * b) / mfl.gcd(a, b)
	end

	mfl.median = function(...)
		local t = { ... }
		table.sort(t)
		local n = #t
		if n % 2 == 1 then
			return t[(n + 1) / 2]
		else
			return (t[n / 2] + t[n / 2 + 1]) / 2
		end
	end

	mfl.range = function(min, max)
		return max - min
	end

	mfl.round = function(n, d)
		d = d or 0
		local m = 10 ^ d
		return math.floor(n * m + 0.5) / m
	end

	mfl.sign = function(n)
		return (n > 0 and 1) or (n < 0 and -1) or 0
	end

	mfl.trunc = function(n)
		return n > 0 and math.floor(n) or math.ceil(n)
	end

	-- Try to evaluate the expression
	local func, err = load("return " .. expr, "expr", "t", mfl)

	if not func then
		return false, tostring(err)
	end

	local success, result = pcall(func)

	if not success then
		return false, tostring(result)
	end

	if type(result) ~= "number" and type(result) ~= "boolean" then
		return false, "Result is not a number, variable or boolean"
	end

	return true, result
end

function M.evaluate(expr, buffer_lines)
	local variables = M.extract_variables(buffer_lines)

	return M.evaluate_expression(expr, variables)
end

function M.format_result(result)
	if type(result) == "boolean" then
		return tostring(result)
	end

	-- Check if it's a very small or very large number
	local abs_result = math.abs(result)
	if (abs_result < 0.001 and result ~= 0) or abs_result > 1000000 then
		return string.format("%.6e", result)
	elseif result == math.floor(result) then
		return string.format("%d", result)
	else
		local formatted = string.format("%.10f", result)
		formatted = formatted:gsub("0+$", ""):gsub("%.$", "")
		return formatted
	end
end

return M
