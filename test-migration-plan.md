# pair-lens.nvim テスト移行計画書

## 概要
js-i18n.nvim のテスト実装方法を参考に、pair-lens.nvim のテスト環境を改善します。
lazy.nvim を活用した効率的なテスト環境の構築と、CI/CD の整備を行います。

## 現状分析

### 現在の pair-lens.nvim のテスト構造
- **フレームワーク**: Busted
- **ディレクトリ構造**:
  ```
  tests/
  ├── busted.lua          # 基本的なセットアップ
  ├── helper.lua          # ヘルパー関数
  └── pair-lens/
      ├── config_spec.lua
      ├── init_spec.lua
      └── utils_spec.lua
  ```
- **課題**:
  - lazy.nvim を活用していない
  - プラグインの依存関係管理が不十分
  - CI/CD が未設定

### js-i18n.nvim から学ぶべき点
1. `lazy.minit.busted()` によるテスト環境の構築
2. プラグインのリロード機構
3. テスト用プロジェクトの動的生成
4. GitHub Actions による自動テスト

## 移行計画

### フェーズ 1: テスト環境の基盤整備（優先度: 高）

#### 1.1 busted.lua の更新
```lua
-- tests/busted.lua
local M = {}

-- lazy.nvim のブートストラップ
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- lazy.minit.busted を使用したプラグイン設定
require("lazy.minit.busted")({
  spec = {
    -- テストに必要な依存関係
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    { 
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      config = function()
        require("nvim-treesitter.configs").setup({
          ensure_installed = { "lua", "javascript", "typescript", "tsx", "json" },
          sync_install = true,
        })
      end,
    },
    -- pair-lens.nvim 本体
    { dir = vim.fn.getcwd() },
  },
})

-- テストの実行
vim.cmd([[runtime! plugin/plenary.vim]])
vim.cmd([[runtime! plugin/**/*.lua]])
vim.cmd([[runtime! plugin/**/*.vim]])

return M
```

#### 1.2 helper.lua の強化
```lua
-- tests/helper.lua
local M = {}

-- グローバルテスト環境の設定
_G._TEST = true

-- lazy.nvim のローダーを取得
local loader = require("lazy.core.loader")

function M.setup()
  -- テスト全体のセットアップ
end

function M.teardown()
  -- テスト全体のクリーンアップ
end

function M.before_each()
  -- 各テスト前の処理
  M.clean_plugin()
end

function M.after_each()
  -- 各テスト後の処理
  -- カーソル位置のリセットなど
  vim.cmd("normal! gg0")
end

function M.clean_plugin()
  -- プラグインの状態をリセット
  loader.reload("pair-lens.nvim", { msg = false })
  
  -- 設定をデフォルトに戻す
  local config = require("pair-lens.config")
  config.setup({})
end

-- テスト用のバッファセットアップ
function M.create_test_buffer(content, filetype)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
  if filetype then
    vim.api.nvim_buf_set_option(buf, "filetype", filetype)
  end
  vim.api.nvim_set_current_buf(buf)
  return buf
end

-- Treesitter のパース待機
function M.wait_for_treesitter()
  vim.wait(100, function()
    return vim.treesitter.get_parser():is_valid()
  end)
end

return M
```

### フェーズ 2: 既存テストの移行（優先度: 中）

#### 2.1 テストファイルの更新例
```lua
-- tests/pair-lens/init_spec.lua
local helper = require("tests.helper")

describe("pair-lens", function()
  setup(helper.setup)
  teardown(helper.teardown)
  before_each(helper.before_each)
  after_each(helper.after_each)

  describe("setup", function()
    it("should setup with default config", function()
      local pair_lens = require("pair-lens")
      local config = require("pair-lens.config")
      
      -- プラグインの再読み込みを確認
      helper.clean_plugin()
      
      pair_lens.setup()
      assert.is_not_nil(config.options)
    end)
  end)

  describe("highlight pairs", function()
    it("should highlight matching parentheses", function()
      -- テスト用バッファの作成
      local content = [[
function test()
  print("hello")
end
      ]]
      helper.create_test_buffer(content, "lua")
      helper.wait_for_treesitter()
      
      -- カーソルを開き括弧に移動
      vim.api.nvim_win_set_cursor(0, {1, 13}) -- '(' の位置
      
      -- ハイライトの更新を待つ
      vim.wait(50)
      
      -- ハイライトの確認
      local highlights = require("pair-lens").get_current_highlights()
      assert.is_not_nil(highlights)
      assert.equals(2, #highlights)
    end)
  end)
end)
```

### フェーズ 3: CI/CD の設定（優先度: 中）

#### 3.1 GitHub Actions ワークフロー
```yaml
# .github/workflows/test.yml
name: Test

on:
  push:
    branches: [main, feat/rebuild]
  pull_request:
    branches: [main]
  schedule:
    # 月次でプラグインキャッシュを更新
    - cron: "0 0 1 * *"

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Neovim
      uses: rhysd/action-setup-vim@v1
      with:
        neovim: true
        version: stable
    
    - name: Setup Lua
      uses: leafo/gh-actions-lua@v10
      with:
        luaVersion: "5.1"
    
    - name: Setup LuaRocks
      uses: leafo/gh-actions-luarocks@v4
    
    - name: Install busted
      run: luarocks install busted
    
    - name: Cache lazy.nvim plugins
      uses: actions/cache@v3
      with:
        path: ~/.local/share/nvim/lazy
        key: ${{ runner.os }}-lazy-${{ hashFiles('tests/busted.lua') }}
        restore-keys: |
          ${{ runner.os }}-lazy-
    
    - name: Run tests
      run: make test
```

### フェーズ 4: Makefile の更新（優先度: 低）

```makefile
# 既存の Makefile に追加
.PHONY: test clean-test test-watch

test:
	@echo "Running tests..."
	nvim --headless -u tests/busted.lua -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/busted.lua' }"

clean-test:
	@echo "Cleaning test artifacts..."
	rm -rf tests/.tmp_*
	rm -rf ~/.local/share/nvim/lazy

test-watch:
	@echo "Watching for changes..."
	@while true; do \
		make test; \
		inotifywait -qre modify lua/ tests/; \
	done
```

### フェーズ 5: 追加のテスト機能（優先度: 低）

#### 5.1 テスト用のサンプルファイル
```
tests/fixtures/
├── javascript/
│   ├── basic.js
│   └── complex.js
├── typescript/
│   └── react.tsx
└── lua/
    └── nested.lua
```

#### 5.2 統合テスト
```lua
-- tests/pair-lens/integration_spec.lua
describe("integration tests", function()
  it("should work with real file structures", function()
    -- fixtures を使用した実際のファイルでのテスト
  end)
end)
```

## 実装スケジュール

1. **週 1**: フェーズ 1 - テスト環境の基盤整備
   - busted.lua と helper.lua の更新
   - 基本的な動作確認

2. **週 2**: フェーズ 2 - 既存テストの移行
   - 各 spec ファイルの更新
   - 新しいヘルパー関数の活用

3. **週 3**: フェーズ 3 - CI/CD の設定
   - GitHub Actions の設定
   - 自動テストの動作確認

4. **週 4**: フェーズ 4-5 - 追加機能
   - Makefile の更新
   - fixtures の追加
   - 統合テストの実装

## 成功指標

- [ ] すべてのテストが lazy.nvim を使用して実行可能
- [ ] GitHub Actions でテストが自動実行される
- [ ] プラグインの状態が各テストで適切にリセットされる
- [ ] Treesitter に依存するテストが安定して動作する
- [ ] テストの実行時間が妥当な範囲内（< 30秒）

## リスクと対策

1. **Treesitter の非同期処理**
   - 対策: `wait_for_treesitter()` ヘルパーで適切に待機

2. **lazy.nvim のバージョン互換性**
   - 対策: stable ブランチを使用し、定期的なキャッシュ更新

3. **CI での Neovim 環境の差異**
   - 対策: Docker イメージの使用も検討

## 参考資料

- [js-i18n.nvim のテスト実装](https://github.com/nabekou29/js-i18n.nvim/tree/main/tests)
- [lazy.nvim minit documentation](https://github.com/folke/lazy.nvim#-minit)
- [Busted documentation](https://lunarmodules.github.io/busted/)