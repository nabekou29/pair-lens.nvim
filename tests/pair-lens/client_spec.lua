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

    it("should update at least every max wait while edits keep coming", function()
      local buf = helper.create_lua_function_buffer()
      update_count = 0

      -- About 1.2s of edits, each sooner than the debounce delay
      for i = 1, 24 do
        vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "-- " .. i })
        vim.wait(50)
      end

      assert.is_true(update_count >= 2, "updates: " .. update_count)

      helper.cleanup_buffer(buf)
    end)

    it("should skip the pending update when the buffer is wiped out", function()
      local buf = helper.create_lua_function_buffer()
      update_count = 0
      vim.v.errmsg = ""

      vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "-- edit" })
      -- Process only fast events, so the timer fires and queues the update,
      -- but the update itself runs only after the buffer is wiped out.
      vim.wait(150, function()
        return false
      end, 10, true)
      helper.cleanup_buffer(buf)
      helper.wait_for_debounce()

      assert.equal(0, update_count)
      assert.equal("", vim.v.errmsg)
    end)
  end)
end)
