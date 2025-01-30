local M = {}

local ns_id = vim.api.nvim_create_namespace("pair-lens")

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

---@param bufnr number バッファ番号
---@return boolean
function M.is_disabled_filetype(bufnr)
  local config = require("pair-lens.config")
  local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
  return vim.tbl_contains(config.options.disable_filetypes, filetype)
end

---@param info PairLens.PairInfo フォーマット情報
---@return string[][]
function M.format_text(info)
  local config = require("pair-lens.config")
  local result = config.options.style.format
  result = result:gsub("{sl}", tostring(info.start_line_number))
  result = result:gsub("{el}", tostring(info.end_line_number))
  result = result:gsub("{st}", trim(info.start_line_text))
  result = result:gsub("{et}", trim(info.end_line_text))
  return { { result, config.options.style.hl } }
end

---@param bufnr number バッファ番号
---@param line number 行番号
---@param text string[][] 表示するテキスト
function M.set_virtual_text(bufnr, line, text)
  pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_id, line, -1, { virt_text = text })
end

---@param bufnr number バッファ番号
function M.clear_virtual_text(bufnr)
  local ns_id = vim.api.nvim_create_namespace("pair-lens")
  pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns_id, 0, -1)
end

return M
