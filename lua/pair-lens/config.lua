local M = {}

M.defaults = {
  enabled = true,
  style = {
    format = "⟸ (:{sl}-{el}) {st}",
    hl = "Comment",
  },
  disable_filetypes = { "help", "terminal", "dashboard" },
  min_lines = 6,
  custom_queries = {},
}

---@param opts? PairLensConfig
---@return PairLensConfig
function M.setup(opts)
  local config = vim.tbl_deep_extend("force", M.defaults, opts or {})

  if not M.validate(config) then
    error("pair-lens: Invalid configuration")
  end

  M.options = config
  return config
end

---@param config any
---@return boolean
function M.validate(config)
  if type(config) ~= "table" then
    return false
  end

  if type(config.enabled) ~= "boolean" then
    return false
  end

  if type(config.style) ~= "table" then
    return false
  end

  if type(config.style.format) ~= "string" and type(config.style.format) ~= "function" then
    return false
  end

  if type(config.style.hl) ~= "string" then
    return false
  end

  if type(config.disable_filetypes) ~= "table" then
    return false
  end

  if type(config.min_lines) ~= "number" or config.min_lines < 0 then
    return false
  end

  if type(config.custom_queries) ~= "table" then
    return false
  end

  return true
end

---@return PairLensConfig
function M.get()
  return M.options or M.defaults
end

function M.is_enabled()
  return M.get().enabled
end

---@param filetype string
---@return boolean
function M.is_filetype_disabled(filetype)
  local disabled_filetypes = M.get().disable_filetypes
  return vim.tbl_contains(disabled_filetypes, filetype)
end

return M

