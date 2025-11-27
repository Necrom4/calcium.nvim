local M = {}

function M.extract_variables(buffer_lines)
	local variables = {}

	local pattern = "^%s*([%w_]+)%s*=%s*(.+)$"

	for _, line in ipairs(buffer_lines) do
		local var_name, var_expr = line:match(pattern)
		if var_name and var_expr then
			-- Remove trailing comments
			var_expr = var_expr:gsub("%s*%-%-.*$", ""):gsub("%s*#.*$", "")
			var_expr = var_expr:gsub("^%s+", ""):gsub("%s+$", "")

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

	-- Replace common mathematical operations
	expr = expr:gsub("%^", "^")

	local math_functions_lib = {
		math = math,
		abs = math.abs,
		acos = math.acos,
		asin = math.asin,
		atan = math.atan,
		atan2 = math.atan2,
		avg = function(...)
			local t = { ... }
			local sum = 0
			for _, v in ipairs(t) do
				sum = sum + v
			end
			return sum / #t
		end,
		ceil = math.ceil,
		clamp = function(n, min, max)
			return math.max(min, math.min(max, n))
		end,
		cos = math.cos,
		cosh = math.cosh,
		deg = math.deg,
		exp = math.exp,
		fact = function(n)
			n = math.floor(n)
			if n < 0 then
				return 0
			end
			local r = 1
			for i = 2, n do
				r = r * i
			end
			return r
		end,
		fib = function(n)
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
		end,
		floor = math.floor,
		fmod = math.fmod,
		gcd = function(a, b)
			a, b = math.abs(a), math.abs(b)
			while b ~= 0 do
				a, b = b, a % b
			end
			return a
		end,
		-- lcm = function(a, b)
		-- 	return math.abs(a * b) / gcd(a, b)
		-- end,
		log = math.log,
		log10 = math.log10,
		max = math.max,
		median = function(...)
			local t = { ... }
			table.sort(t)
			local n = #t
			if n % 2 == 1 then
				return t[(n + 1) / 2]
			else
				return (t[n / 2] + t[n / 2 + 1]) / 2
			end
		end,
		min = math.min,
		modf = math.modf,
		pi = math.pi,
		pow = math.pow,
		rad = math.rad,
		random = math.random,
		range = function(min, max)
			return max - min
		end,
		round = function(n, d)
			d = d or 0
			local m = 10 ^ d
			return math.floor(n * m + 0.5) / m
		end,
		sign = function(n)
			return (n > 0 and 1) or (n < 0 and -1) or 0
		end,
		sin = math.sin,
		sinh = math.sinh,
		sqrt = math.sqrt,
		tan = math.tan,
		tanh = math.tanh,
		trunc = function(n)
			return n > 0 and math.floor(n) or math.ceil(n)
		end,
	}

	-- Try to evaluate the expression
	local func, err = load("return " .. expr, "expr", "t", math_functions_lib)

	if not func then
		return false, "Syntax error: " .. tostring(err)
	end

	local success, result = pcall(func)

	if not success then
		return false, "Evaluation error: " .. tostring(result)
	end

	if type(result) ~= "number" then
		return false, "Result is not a number"
	end

	return true, result
end

function M.evaluate(expr, buffer_lines)
	local variables = M.extract_variables(buffer_lines)

	return M.evaluate_expression(expr, variables)
end

function M.format_result(result)
	-- Check if it's a very small or very large number
	if math.abs(result) < 0.001 and result ~= 0 then
		return string.format("%.6e", result)
	elseif math.abs(result) > 1000000 then
		return string.format("%.6e", result)
	else
		if result == math.floor(result) then
			return string.format("%d", result)
		else
			local formatted = string.format("%.10f", result)
			formatted = formatted:gsub("0+$", ""):gsub("%.$", "")
			return formatted
		end
	end
end

return M
