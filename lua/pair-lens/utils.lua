local M = {}

---@param bufnr number
---@param line_nr number
---@return string|nil
function M.get_line_text(bufnr, line_nr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line_nr < 0 or line_nr >= line_count then
    return nil
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, line_nr, line_nr + 1, false)
  return lines[1] or ""
end

---@param node any
---@param bufnr number
---@return PairLensNodeInfo|nil
function M.extract_node_info(node, bufnr)
  if not node then
    return nil
  end

  local start_row, start_col, end_row, end_col = node:range()

  local start_text = M.get_line_text(bufnr, start_row)
  local end_text = M.get_line_text(bufnr, end_row)

  if not start_text or not end_text then
    return nil
  end

  start_text = vim.trim(start_text)
  end_text = vim.trim(end_text)

  local node_text = vim.treesitter.get_node_text(node, bufnr)

  return {
    start_line = start_row + 1,
    end_line = end_row + 1,
    start_text = start_text,
    end_text = end_text,
    line_count = end_row - start_row + 1,
    node_text = node_text,
    bufnr = bufnr,
    node_type = node:type(),
    lang = vim.bo[bufnr].filetype,
  }
end

function M.log_debug(...)
  if vim.g.pair_lens_debug then
    print("[pair-lens]", ...)
  end
end

---Calls `fn` once `delay` ms have passed without another call. With `max_wait`,
---a continuous stream of calls still runs `fn` at least every `max_wait` ms.
---@param fn function
---@param delay number
---@param max_wait? number
---@return function debounced
---@return function close Cancels a pending call and releases the timer
function M.debounce(fn, delay, max_wait)
  local timer = assert(vim.uv.new_timer())
  local first_call_at = nil
  local args = {}

  local function debounced(...)
    args = { ... }
    local now = vim.uv.now()
    first_call_at = first_call_at or now

    local wait = delay
    if max_wait then
      wait = math.max(0, math.min(delay, first_call_at + max_wait - now))
    end

    timer:stop()
    timer:start(wait, 0, function()
      first_call_at = nil
      vim.schedule(function()
        fn(unpack(args))
      end)
    end)
  end

  local function close()
    timer:stop()
    if not timer:is_closing() then
      timer:close()
    end
  end

  return debounced, close
end

---@param cursor_line number
---@param start_line number
---@param end_line number
---@return boolean
function M.is_cursor_in_range(cursor_line, start_line, end_line)
  return cursor_line >= start_line and cursor_line <= end_line
end

---@param node_info PairLensNodeInfo|nil
---@param config PairLensConfig
---@return boolean
function M.should_show_lens(node_info, config)
  if not node_info then
    return false
  end

  if node_info.line_count < config.min_lines then
    return false
  end

  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  if M.is_cursor_in_range(cursor_line, node_info.start_line, node_info.end_line) then
    return false
  end

  return true
end

---@param bufnr number
---@param namespace number
function M.clear_virtual_text(bufnr, namespace)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  end
end

return M
