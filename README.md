# 🧮 calcium.nvim

A powerful Neovim plugin to calculate mathematical expressions with visual mode and variable support.

## ✨ Features

- 👍 **Simple & Complex Expressions**: Handle any mathematical expression, see [𝑓unctions](#𝑓-available-functions) section.
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
:Calcium [append|a|replace|r]

" Calculate the expression in the visual selection and replace with the result
:'<,'>Calcium replace
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

- Trigonometry: `sin`, `cos`, `tan`, `asin`, `acos`, `atan`, `atan2`
- Hyperbolic: `sinh`, `cosh`, `tanh`
- Exponential: `exp`, `log`, `log10`
- Rounding: `floor`, `ceil`
- Other: `sqrt`, `abs`, `min`, `max`, `pow`, `deg`, `rad`
- Constants: `pi`

## 🏆 Roadmap

- [ ] Quick fixes before publishing
  - [x] Remove `CalciumAppend` and `CalciumReplace` commands
  - [x] Use `mode` and `visual` vars instead of `opts` for `calculate()`
  - [ ] Notification title
- [ ] Fix
  - [ ] Keep indention for `:Calcium replace`
  - [ ] `./plugin/calcium.lua`, should it have more checks? Should everything be in another path (so it doesn't load on start), should it have the global variable check?
- [ ] Cmdline `<mode>` suggestions
- [ ] Cmdline calculations
- [ ] Smart selection when no visual selection is provided (e.g., "I have `2 + 1` cats")
- [ ] Boolean result when a `=` is already present
- [ ] Playground mode, a small window in which the results are displayed live while typing
