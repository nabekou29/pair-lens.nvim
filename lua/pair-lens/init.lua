local config = require("pair-lens.config")
local queries = require("pair-lens.queries")
local utils = require("pair-lens.utils")

local M = {}

---@param node TSNode
---@return string
local function get_line_text(node)
  local start_row = node:start()
  local bufnr = vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
  return line
end

---@param bufnr number
local function attach_to_buffer(bufnr)
  if utils.is_disabled_filetype(bufnr) then
    return
  end

  -- Tree-sitter のパーサーを取得
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    return
  end

  local function update_virtual_text()
    if not config.enabled then
      utils.clear_virtual_text(bufnr)
      return
    end

    utils.clear_virtual_text(bufnr)

    -- Tree-sitter で構文木を取得
    local tree = parser:parse()[1]
    local root = tree:root()

    -- 言語に応じたクエリを取得
    local lang = parser:lang()
    local query_string = queries.get_query(lang)
    if not query_string then
      return
    end

    -- クエリを実行
    local ok, query = pcall(vim.treesitter.query.parse, lang, query_string)
    if not ok then
      return
    end

    for id, node in query:iter_captures(root, bufnr, 0, -1) do
      local _capture_name = query.captures[id]
      local start_row, _, end_row, _ = node:range()

      -- 開始位置から終了位置までの行数をチェック
      local lines_between = end_row - start_row + 1
      if lines_between >= config.options.min_lines then
        ---@type PairLens.PairInfo
        local pair = {
          start_line_number = start_row + 1,
          start_line_text = get_line_text(node),
          end_line_number = end_row + 1,
          end_line_text = get_line_text(node),
        }

        local display_text = utils.format_text(pair)
        utils.set_virtual_text(bufnr, end_row, display_text)
      end
    end
  end

  -- バッファの変更を監視
  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = function()
      vim.defer_fn(update_virtual_text, 100)
    end,
    on_detach = function()
      utils.clear_virtual_text(bufnr)
    end,
  })

  -- 初回実行
  update_virtual_text()
end

---@param opts? PairLens.Config
function M.setup(opts)
  config.setup(opts)

  local group = vim.api.nvim_create_augroup("PairLens", {})
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = group,
    callback = function(args)
      attach_to_buffer(args.buf)
    end,
  })
end

-- グローバルな有効/無効の切り替え
function M.enable()
  config.enabled = true
  -- 全バッファに対して更新を実行
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      attach_to_buffer(bufnr)
    end
  end
end

function M.disable()
  config.enabled = false
  -- 全バッファの virtual text をクリア
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      utils.clear_virtual_text(bufnr)
    end
  end
end

function M.toggle()
  if config.enabled then
    M.disable()
  else
    M.enable()
  end
end

return M
