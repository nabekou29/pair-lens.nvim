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
  return vim.trim(line or "")
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

  local virtual_texts_by_line = {}

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

      if
        not virtual_texts_by_line[end_row]
        or virtual_texts_by_line[end_row].line_count < lines_between
      then
        virtual_texts_by_line[end_row] = {
          virt_text = virt_text_table,
          line_count = lines_between,
        }
      end
    end
  end

  for row, vtext_info in pairs(virtual_texts_by_line) do
    -- Check if row is within buffer bounds
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    if row >= 0 and row < line_count then
      vim.api.nvim_buf_set_extmark(bufnr, self.namespace, row, -1, {
        virt_text = vtext_info.virt_text,
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

  -- A single timer per buffer coalesces a burst of edits into one update,
  -- since each update re-renders the whole buffer.
  local timer = assert(vim.uv.new_timer())
  local deferred_update = vim.schedule_wrap(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      update_virtual_text()
    end
  end)

  local function schedule_update()
    timer:stop()
    timer:start(100, 0, deferred_update)
  end

  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = schedule_update,
    -- Without on_reload, reloading the file from disk detaches this callback.
    on_reload = schedule_update,
    on_detach = function()
      timer:stop()
      timer:close()
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

  local values = {
    sl = node_info.start_line,
    start_line = node_info.start_line,
    el = node_info.end_line,
    end_line = node_info.end_line,
    st = node_info.start_text,
    start_text = node_info.start_text,
    et = node_info.end_text,
    end_text = node_info.end_text,
    lc = node_info.line_count,
    line_count = node_info.line_count,
  }

  -- Replace via a function in a single pass: a string replacement would treat
  -- "%" in the source text as a capture reference, and later passes would
  -- expand placeholders that appear in the inserted source text.
  local text = format:gsub("{([%w_]+)}", function(key)
    local value = values[key]
    return value ~= nil and tostring(value) or nil
  end)

  return text
end

return Client
