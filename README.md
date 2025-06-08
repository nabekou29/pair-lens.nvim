# pair-lens.nvim

[日本語](README.ja.md) | **English**

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim](https://img.shields.io/badge/Neovim%200.8+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)

A Neovim plugin that displays information about the corresponding start position at the end of block structures (such as `end`).

![Demo](./demo.gif)

## Features

- Multi-language support
  - Lua: `if ... then ... end`, `do ... end`, `function ... end`
  - Ruby: `if ... end`, `def ... end`, `do ... end`, `class ... end`
  - Python: `def`, `class`, `if`, `for`, `while`, `try`, `with`
  - JavaScript/TypeScript: functions, classes, methods, control structures
  - Rust: functions, impl, structs, enums, traits, control structures
  - Go: functions, methods, type definitions, control structures
- Accurate syntax parsing using Tree-sitter
- Lightweight and fast operation
- Customizable display styles

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "nabekou29/pair-lens.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("pair-lens").setup()
  end,
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "nabekou29/pair-lens.nvim",
  requires = {
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("pair-lens").setup()
  end,
}
```

## Configuration

```lua
require("pair-lens").setup({
  -- Default configuration
  enabled = true,
  style = {
    -- Display format
    -- {sl} / {start_line}: Start position line number
    -- {el} / {end_line}: End position line number
    -- {st} / {start_text}: Start position text
    -- {et} / {end_text}: End position text
    -- {lc} / {line_count}: Number of lines in the block
    format = "󰶢 (:{start_line}-{end_line}) {start_text}",
    -- Highlight group
    hl = "PairLensVirtualText",
  },
  -- Disabled file types
  disable_filetypes = {},
  -- Custom queries (override Tree-sitter queries)
  custom_queries = {
    -- Example: Custom query for Lua
    -- lua = [[
    --   (function_definition) @function
    --   (if_statement) @if
    -- ]],
  },
  -- Minimum number of lines to display (default: 5)
  -- Virtual text will not be displayed if the number of lines from start to end is less than this value
  min_lines = 6,
})
```

### Advanced Customization

You can also specify a function for the format field. The function receives `PairLensNodeInfo` and returns either a string or an array of string and highlight group pairs:

```lua
require("pair-lens").setup({
  style = {
    -- Advanced formatting with multiple highlight groups
    format = function(info)
      local line_info = string.format("(%d:%d-%d) ", info.line_count, info.start_line, info.end_line)
      local start_text = info.start_text
      return {
        { "󰶢 ", "PairLensVirtualText" },
        { line_info, "PairLensVirtualTextNum" },
        { start_text, "PairLensVirtualTextCode" },
      }
    end,
  },
})
```

This example allows you to display icons, line count information, and start position text with different highlight groups.

## Commands

| Command            | Description                    |
| ------------------ | ------------------------------ |
| `:PairLensEnable`  | Enable the plugin             |
| `:PairLensDisable` | Disable the plugin            |
| `:PairLensToggle`  | Toggle plugin enable/disable  |

## License

MIT

## Credits

This plugin is inspired by [bracket-lens](https://github.com/wraith13/bracket-lens-vscode).