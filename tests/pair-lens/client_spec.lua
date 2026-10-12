local helper = require("tests.helper")

describe("client", function()
  setup(helper.setup)
  teardown(helper.teardown)
  before_each(helper.before_each)
  after_each(helper.after_each)

  local client
  local update_count

  before_each(function()
    client = helper.setup_test_environment().get_client()

    update_count = 0
    local update = client.update_virtual_text_for_buffer
    client.update_virtual_text_for_buffer = function(...)
      update_count = update_count + 1
      return update(...)
    end
  end)

  describe("format_virtual_text", function()
    local function format(start_text)
      return client:format_virtual_text({
        start_line = 1,
        end_line = 10,
        start_text = start_text,
        end_text = "}",
        line_count = 10,
      }, { format = "(:{sl}-{el}) {st}", hl = "Comment" })
    end

    it("should keep % in the source text as is", function()
      assert.equal("(:1-10) if i%2 == 0 {", format("if i%2 == 0 {"))
      assert.equal("(:1-10) // 0-100% complete", format("// 0-100% complete"))
    end)

    it("should not expand placeholders in the source text", function()
      assert.equal('(:1-10) local s = "{lc}"', format('local s = "{lc}"'))
    end)
  end)

  describe("on edit", function()
    it("should update once for a burst of edits", function()
      local buf = helper.create_lua_function_buffer()
      update_count = 0

      for i = 1, 5 do
        vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "-- " .. i })
      end
      helper.wait_for_debounce()

      assert.equal(1, update_count)

      helper.cleanup_buffer(buf)
    end)

    it("should skip the pending update when the buffer is wiped out", function()
      local buf = helper.create_lua_function_buffer()
      update_count = 0

      vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "-- edit" })
      helper.cleanup_buffer(buf)
      helper.wait_for_debounce()

      assert.equal(0, update_count)
    end)

    it("should not attach twice after the buffer is unlisted and listed again", function()
      local buf = helper.create_lua_function_buffer()
      local other = vim.api.nvim_create_buf(true, true)

      for _ = 1, 3 do
        vim.bo[buf].buflisted = false
        vim.bo[buf].buflisted = true
        vim.api.nvim_set_current_buf(other)
        vim.api.nvim_set_current_buf(buf)
      end
      helper.wait_for_debounce()
      update_count = 0

      vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "-- edit" })
      helper.wait_for_debounce()

      assert.equal(1, update_count)

      helper.cleanup_buffer(other)
      helper.cleanup_buffer(buf)
    end)

    it("should forget the buffer once it is unloaded by :bdelete", function()
      local buf = helper.create_lua_function_buffer()
      assert.is_not_nil(client.buffers[buf])

      vim.cmd.bdelete({ args = { buf }, bang = true })

      assert.is_nil(client.buffers[buf])

      helper.cleanup_buffer(buf)
    end)
  end)

  describe("on filetype change", function()
    local function create_buffer(filetype)
      local scratch = helper.create_lua_function_buffer()
      local lines = vim.api.nvim_buf_get_lines(scratch, 0, -1, false)
      helper.cleanup_buffer(scratch)
      return helper.create_test_buffer(table.concat(lines, "\n"), filetype)
    end

    it("should show lenses once a filetype is set on a shown buffer", function()
      local buf = create_buffer(nil)
      assert.is_nil(helper.get_virtual_text(buf, 6))

      vim.bo[buf].filetype = "lua"

      assert.is_not_nil(helper.get_virtual_text(buf, 6))

      helper.cleanup_buffer(buf)
    end)

    it("should use the parser for the new filetype", function()
      local buf = create_buffer("json")
      assert.is_nil(helper.get_virtual_text(buf, 6))

      vim.bo[buf].filetype = "lua"

      assert.is_not_nil(helper.get_virtual_text(buf, 6))

      helper.cleanup_buffer(buf)
    end)
  end)

  describe("on reload", function()
    it("should keep the lenses after the file is reloaded from disk", function()
      local path = vim.fn.tempname() .. ".lua"
      local scratch = helper.create_lua_function_buffer()
      local lines = vim.api.nvim_buf_get_lines(scratch, 0, -1, false)
      helper.cleanup_buffer(scratch)
      vim.fn.writefile(lines, path)
      vim.cmd.edit(path)
      local buf = vim.api.nvim_get_current_buf()
      helper.wait_for_treesitter()

      vim.fn.writefile(vim.list_extend({ "-- changed" }, lines), path)
      local future = os.time() + 10
      vim.uv.fs_utime(path, future, future)
      vim.bo[buf].autoread = true
      vim.cmd.checktime(buf)
      helper.wait_for_debounce()

      assert.equal("-- changed", vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1])
      assert.is_not_nil(helper.get_virtual_text(buf, 7))

      vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "-- edit" })
      helper.wait_for_debounce()
      assert.is_not_nil(helper.get_virtual_text(buf, 8))

      helper.cleanup_buffer(buf)
      vim.fn.delete(path)
    end)
  end)
end)
