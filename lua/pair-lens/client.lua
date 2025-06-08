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

---@param node TSNode
---@param bufnr number
---@return string
local function get_line_text(node, bufnr)
  local start_row = node:start()
  local line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
  return line or ""
end

---@param bufnr number
---@param parser vim.treesitter.LanguageTree
function Client:update_virtual_text_for_buffer(bufnr, parser)
  if not config.is_enabled() then
    utils.clear_virtual_text(bufnr, self.namespace)
    return
  end

  utils.clear_virtual_text(bufnr, self.namespace)

  local tree = parser:parse()[1]
  if not tree then
    return
  end

  local root = tree:root()
  local lang = parser:lang()
  local query = queries.get_parsed_query(lang, config.get().custom_queries)
  if not query then
    return
  end

  for id, node in query:iter_captures(root, bufnr, 0, -1) do
    local start_row, _, end_row, _ = node:range()
    local lines_between = end_row - start_row + 1
    local conf = config.get()

    if lines_between >= conf.min_lines then
      local node_info = {
        start_line = start_row + 1,
        end_line = end_row + 1,
        start_text = get_line_text(node, bufnr),
        end_text = get_line_text(node, bufnr),
        line_count = lines_between,
      }

      local virtual_text = self:format_virtual_text(node_info, conf.style)
      local virt_text_table

      if type(virtual_text) == "table" then
        virt_text_table = virtual_text
      else
        virt_text_table = { { virtual_text, conf.style.hl } }
      end

      vim.api.nvim_buf_set_extmark(bufnr, self.namespace, end_row, -1, {
        virt_text = virt_text_table,
        virt_text_pos = "eol",
      })
    end
  end
end

---@param bufnr number
function Client:attach_to_buffer(bufnr)
  if self.buffers[bufnr] then
    return
  end

  local filetype = vim.bo[bufnr].filetype
  if config.is_filetype_disabled(filetype) then
    return
  end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    return
  end

  local function update_virtual_text()
    self:update_virtual_text_for_buffer(bufnr, parser)
  end

  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = function()
      vim.defer_fn(update_virtual_text, 100)
    end,
    on_detach = function()
      self:clear_buffer(bufnr)
    end,
  })

  self.buffers[bufnr] = true
  update_virtual_text()
end

function Client:create_autocmds()
  if self.autocmd_group then
    vim.api.nvim_del_augroup_by_id(self.autocmd_group)
  end

  self.autocmd_group = vim.api.nvim_create_augroup("PairLens", { clear = true })

  vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter", "BufWinEnter" }, {
    group = self.autocmd_group,
    callback = function(args)
      self:attach_to_buffer(args.buf)
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
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      if self.buffers[bufnr] then
        -- Already attached, just update virtual text
        local filetype = vim.bo[bufnr].filetype
        if not config.is_filetype_disabled(filetype) then
          local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
          if ok and parser then
            self:update_virtual_text_for_buffer(bufnr, parser)
          end
        end
      else
        self:attach_to_buffer(bufnr)
      end
    end
  end
  vim.notify("pair-lens: Enabled")
end

function Client:disable()
  config.options.enabled = false
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      utils.clear_virtual_text(bufnr, self.namespace)
    end
  end
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
  utils.clear_virtual_text(bufnr, self.namespace)
end

---@param node_info table
---@param format_config PairLensStyleConfig
---@return string|string[][]
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

return Client
