local M = {}

---@type PairLens.Config
local defaults = {
  enabled = true,
  -- Options
  style = {
    format = "⟸ (:{sl}-{el}) {st}",
    hl = "Comment",
  },
  disable_filetypes = {},
  pairs = {},
  min_lines = 5,
}

M.options = {}
M.enabled = true

---@param opts? PairLens.Config
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, defaults, opts or {})
  M.enabled = M.options.enabled
end

return M
