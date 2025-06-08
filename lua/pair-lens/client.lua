local config = require("pair-lens.config")
local queries = require("pair-lens.queries")
local utils = require("pair-lens.utils")

local Client = {}
Client.__index = Client

---@return PairLensClient
function Client.new()
  local self = setmetatable({}, Client)
  self.namespace = vim.api.nvim_create_namespace("pair-lens")
  self.buffers = {}
  self.autocmd_group = nil
  return self
end

function Client:setup()
  self:create_autocmds()
  self:create_commands()
end

function Client:create_autocmds()
  if self.autocmd_group then
    vim.api.nvim_del_augroup_by_id(self.autocmd_group)
  end

  self.autocmd_group = vim.api.nvim_create_augroup("PairLens", { clear = true })

  local update_debounced = utils.debounce(function(bufnr)
    self:update_buffer(bufnr)
  end, 100)

  vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "InsertLeave" }, {
    group = self.autocmd_group,
    callback = function(args)
      local bufnr = args.buf

      if not config.is_enabled() then
        return
      end

      local filetype = vim.bo[bufnr].filetype
      if config.is_filetype_disabled(filetype) then
        return
      end

      if not vim.treesitter.highlighter.active[bufnr] then
        return
      end

      update_debounced(bufnr)
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    group = self.autocmd_group,
    callback = function(args)
      self:clear_buffer(args.buf)
    end,
  })
end

function Client:create_commands()
  vim.api.nvim_create_user_command("PairLensEnable", function()
    self:enable()
  end, {})

  vim.api.nvim_create_user_command("PairLensDisable", function()
    self:disable()
  end, {})

  vim.api.nvim_create_user_command("PairLensToggle", function()
    self:toggle()
  end, {})
end

function Client:enable()
  config.options.enabled = true
  self:update_all_buffers()
  vim.notify("pair-lens: Enabled")
end

function Client:disable()
  config.options.enabled = false
  self:clear_all_virtual_text()
  vim.notify("pair-lens: Disabled")
end

function Client:toggle()
  if config.is_enabled() then
    self:disable()
  else
    self:enable()
  end
end

---@param bufnr number
function Client:clear_buffer(bufnr)
  self.buffers[bufnr] = nil
  self:clear_virtual_text(bufnr)
end

---@param bufnr number
function Client:clear_virtual_text(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, self.namespace, 0, -1)
  end
end

function Client:clear_all_virtual_text()
  for bufnr, _ in pairs(self.buffers) do
    self:clear_virtual_text(bufnr)
  end
end

function Client:update_all_buffers()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      self:update_buffer(bufnr)
    end
  end
end

---@param node_info PairLensNodeInfo
---@param format_config PairLensStyleConfig
---@return string
function Client:format_virtual_text(node_info, format_config)
  local format = format_config.format

  if type(format) == "function" then
    return format(node_info)
  end

  local text = format
  text = text:gsub("{sl}", tostring(node_info.start_line))
  text = text:gsub("{start_line}", tostring(node_info.start_line))
  text = text:gsub("{el}", tostring(node_info.end_line))
  text = text:gsub("{end_line}", tostring(node_info.end_line))
  text = text:gsub("{st}", node_info.start_text)
  text = text:gsub("{start_text}", node_info.start_text)
  text = text:gsub("{et}", node_info.end_text)
  text = text:gsub("{end_text}", node_info.end_text)
  text = text:gsub("{lc}", tostring(node_info.line_count))
  text = text:gsub("{line_count}", tostring(node_info.line_count))

  return text
end

---@param bufnr number
function Client:update_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local filetype = vim.bo[bufnr].filetype
  local conf = config.get()

  self:clear_virtual_text(bufnr)

  if not config.is_enabled() or config.is_filetype_disabled(filetype) then
    return
  end

  local query = queries.get_parsed_query(filetype, conf.custom_queries)
  if not query then
    return
  end

  local parser = vim.treesitter.get_parser(bufnr, filetype)
  if not parser then
    return
  end

  local tree = parser:parse()[1]
  if not tree then
    return
  end

  local root = tree:root()

  for id, node in query:iter_captures(root, bufnr, 0, -1) do
    local node_info = utils.extract_node_info(node, bufnr)

    if node_info and utils.should_show_lens(node_info, conf) then
      local virtual_text = self:format_virtual_text(node_info, conf.style)

      vim.api.nvim_buf_set_extmark(bufnr, self.namespace, node_info.end_line - 1, -1, {
        virt_text = { { virtual_text, conf.style.hl } },
        virt_text_pos = "eol",
      })
    end
  end

  self.buffers[bufnr] = true
  utils.log_debug("Updated virtual text for buffer", bufnr)
end

return Client
