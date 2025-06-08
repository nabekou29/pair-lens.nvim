# pair-lens.nvim

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](http://www.lua.org)
[![Neovim](https://img.shields.io/badge/Neovim%200.8+-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io)

ブロック構造の終端（`end` など）に、対応する開始位置の情報を表示する Neovim プラグインです。

![Demo](./demo.gif)

## 特徴

- 多言語対応
  - Lua: `if ... then ... end`, `do ... end`, `function ... end`
  - Ruby: `if ... end`, `def ... end`, `do ... end`, `class ... end`
  - Python: `def`, `class`, `if`, `for`, `while`, `try`, `with`
  - JavaScript/TypeScript: 関数、クラス、メソッド、制御構文
  - Rust: 関数、impl、構造体、enum、trait、制御構文
  - Go: 関数、メソッド、型定義、制御構文
- Tree-sitter を使用した正確な構文解析
- 軽量で高速な動作
- カスタマイズ可能な表示スタイル

## インストール

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

## 設定

```lua
require("pair-lens").setup({
  -- デフォルト設定
  enabled = true,
  style = {
    -- 表示フォーマット
    -- {sl} / {start_line}: 開始位置の行番号
    -- {el} / {end_line}: 終了位置の行番号
    -- {st} / {start_text}: 開始位置の文字列
    -- {et} / {end_text}: 終了位置の文字列
    -- {lc} / {line_count}: ブロックの行数
    format = "󰶢 (:{start_line}-{end_line}) {start_text}",
    -- ハイライトグループ
    hl = "Comment",
  },
  -- 無効にするファイルタイプ
  disable_filetypes = {},
  -- カスタムクエリ（Tree-sitterクエリをオーバーライド）
  custom_queries = {
    -- 例: Luaのカスタムクエリ
    -- lua = [[
    --   (function_definition) @function
    --   (if_statement) @if
    -- ]],
  },
  -- 表示する最小行数（デフォルト: 5）
  -- 開始位置から終了位置までの行数がこの値未満の場合は表示しません
  min_lines = 6,
})
```

## コマンド

| コマンド           | 説明                            |
| ------------------ | ------------------------------- |
| `:PairLensEnable`  | プラグインを有効化              |
| `:PairLensDisable` | プラグインを無効化              |
| `:PairLensToggle`  | プラグインの有効/無効を切り替え |

## ライセンス

MIT

## クレジット

このプラグインは [bracket-lens](https://github.com/wraith13/bracket-lens-vscode) から着想を得ています。
