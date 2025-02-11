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
  style = {
    -- 表示位置（virtual text の位置）
    position = "eol", -- "eol" | "overlay"
    -- 表示フォーマット
    -- %s: 開始位置の文字列
    -- %l: 開始位置の行番号
    format = "⟸ (:%l) %s",
  },
  -- 無効にするファイルタイプ
  disable_filetypes = {},
  -- 追加のキーワードペア
  pairs = {
    -- 例: Rust の match 式
    -- rust = {
    --   match_arm = { start = "match", mid = "=>", last = "," },
    -- },
  },
  -- 表示する最小行数（デフォルト: 3）
  -- 開始位置から終了位置までの行数がこの値未満の場合は表示しません
  min_lines = 6,
})
```

## コマンド

| コマンド | 説明 |
|----------|------|
| `:PairLensEnable` | プラグインを有効化 |
| `:PairLensDisable` | プラグインを無効化 |
| `:PairLensToggle` | プラグインの有効/無効を切り替え |

## ライセンス

MIT

## クレジット

このプラグインは [bracket-lens](https://github.com/wraith13/bracket-lens-vscode) から着想を得ています。
