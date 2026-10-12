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
  end)
end)
