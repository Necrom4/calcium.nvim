# 🧮 calcium.nvim

A powerful [`lua-lib-math`](https://www.lua.org/pil/18.html) in-buffer calculator with visual mode, functions and variable support.

![calcium](https://github.com/user-attachments/assets/4e805a43-2f8c-44ec-919e-fef4e65611b3)

## ✨ Features

- 👍 **Simple & Complex Expressions**: Handle any mathematical expression, see the [𝑓unctions](#𝑓-available-functions) section.
- 𝑓𝑥 **Variable Support**: Use variables anywhere in your buffer.
- 🎯 **Work in the buffer**: Evaluates expression in visual selection or current line.

## 📦 Installation

#### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "necrom4/calcium.nvim",
  cmd = { "Calcium" },
  opts = {}
}
```

## ⚙️ Configuration

```lua
{
  "necrom4/calcium.nvim",
  cmd = { "Calcium" },
  opts = {
    -- default configuration
    notifications = true, -- notify result
    default_mode = "append", -- or `replace` the expression
  },
  keys = {
    -- example keymap
    {
      "<leader>c",
      ":Calcium<CR>",
      desc = "Calculate",
      mode = { "n", "v" },
      silent = true,
    },
  }
}
```

## 🚀 Usage

```vim
" Append the result at the end of the expression in the current line
:Calcium

" Append the result or replace the expression by the result
:Calcium [a]ppend|[r]eplace

" Calculate the expression in the visual selection and replace with the result
:'<,'>Calcium replace

" Calculate an expression in the cmdline
:Calcium 2 + pi * random()

```

```lua
-- Calculate the expression in the visual selection and append result
require("calcium").calculate({ mode = "append", visual = true })
```

**Examples**:

```lua
-- Select [2 + 2] and run `:Calcium`
x = 2 + 2 -- = 4

-- Select [x * pi] and run `:Calcium`
y = x * pi -- = 12.5663706144
```

#### 𝑓 Available functions

- **Trigonometry**: `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2`
- **Hyperbolic**: `sinh`, `cosh`, `tanh`
- **Exponential & Logarithmic**: `exp`, `log`, `log10`, `pow`, `sqrt`
- **Angle Conversion**: `deg`, `rad`
- **Rounding & Truncation**: `floor`, `ceil`, `round`, `trunc`
- **Basic Arithmetic**: `abs`, `min`, `max`, `clamp`, `sign`, `fmod`, `modf`
- **Number Theory**: `gcd`, `lcm`, `fact`
- **Statistics**: `avg`, `median`, `range`, `fib`
- **Floating Point**: `frexp`, `ldexp`
- **Random**: `random`, `randomseed`
- **Constants**: `pi`, `huge`
- **Boolean**: `==`, `~=`, `>`, `<`, `>=`, `<=`

## 🏆 Roadmap

- [ ] Fix
  - [ ] `./plugin/calcium.lua`, should it have more checks? Should everything be in another path (so it doesn't load on start), should it have the global variable check?
- [x] Cmdline `<mode>` suggestions
- [x] Cmdline calculations
- [x] Boolean result (`2 + 2 >= 3` `= true`)
- [x] Smart selection when no visual selection is provided. In "I have `2 + 1` cats", the cursor must find the closest expression and solve it.
- [ ] Playground mode, a small window in which the results are displayed live while typing
