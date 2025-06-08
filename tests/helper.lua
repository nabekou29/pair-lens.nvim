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

function M.get_virtual_text(buf, line)
  local ns_id = vim.api.nvim_create_namespace("pair-lens")
  local extmarks = vim.api.nvim_buf_get_extmarks(
    buf,
    ns_id,
    { line, 0 },
    { line, -1 },
    { details = true }
  )

  for _, extmark in ipairs(extmarks) do
    local details = extmark[4]
    if details and details.virt_text then
      return details.virt_text
    end
  end

  return nil
end

function M.cleanup_buffer(buf)
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
end

function M.wait_for_debounce()
  vim.wait(150)
end

function M.setup_test_environment()
  M.clean_plugin()

  local pair_lens = require("pair-lens")
  pair_lens.setup({
    enabled = true,
    style = {
      format = "⟸ (:{sl}-{el}) {st}",
      hl = "Comment",
    },
    min_lines = 3,
  })

  return pair_lens
end

function M.create_lua_function_buffer()
  local content = [[
function test()
  if true then
    print("hello")
    for i = 1, 10 do
      print(i)
    end
  end
end]]

  return M.create_test_buffer(content, "lua")
end

return M

