local helper = require("tests.helper")

describe("utils", function()
  setup(helper.setup)
  teardown(helper.teardown)
  before_each(helper.before_each)
  after_each(helper.after_each)

  local utils

  before_each(function()
    package.loaded["pair-lens.utils"] = nil
    utils = require("pair-lens.utils")
  end)

  describe("get_line_text", function()
    it("should return line text for valid buffer and line", function()
      local buf = helper.create_test_buffer("line 1\nline 2\nline 3")

      local text = utils.get_line_text(buf, 0)
      assert.equal("line 1", text)

      local text2 = utils.get_line_text(buf, 1)
      assert.equal("line 2", text2)

      helper.cleanup_buffer(buf)
    end)

    it("should return nil for invalid buffer", function()
      local text = utils.get_line_text(999, 0)
      assert.is_nil(text)
    end)

    it("should return nil for invalid line number", function()
      local buf = helper.create_test_buffer("line 1")

      local text = utils.get_line_text(buf, -1)
      assert.is_nil(text)

      local text2 = utils.get_line_text(buf, 10)
      assert.is_nil(text2)

      helper.cleanup_buffer(buf)
    end)
  end)

  describe("debounce", function()
    it("should delay function execution", function()
      local called = false
      local fn = utils.debounce(function()
        called = true
      end, 50)

      fn()
      assert.is_false(called)

      vim.wait(100)
      assert.is_true(called)
    end)
  end)

  describe("is_cursor_in_range", function()
    it("should check if cursor is in range", function()
      assert.is_true(utils.is_cursor_in_range(5, 1, 10))
      assert.is_true(utils.is_cursor_in_range(1, 1, 10))
      assert.is_true(utils.is_cursor_in_range(10, 1, 10))
      assert.is_false(utils.is_cursor_in_range(0, 1, 10))
      assert.is_false(utils.is_cursor_in_range(11, 1, 10))
    end)
  end)

  describe("should_show_lens", function()
    it("should return false for small blocks", function()
      local node_info = { line_count = 3 }
      local config = { min_lines = 5 }

      assert.is_false(utils.should_show_lens(node_info, config))
    end)

    it("should return true for large blocks", function()
      local buf = helper.create_test_buffer(
        "line1\nline2\nline3\nline4\nline5\nline6\nline7\nline8\nline9\nline10\nline11\nline12\nline13\nline14\nline15\nline16\nline17\nline18\nline19\nline20"
      )

      local node_info = {
        line_count = 10,
        start_line = 1,
        end_line = 10,
      }
      local config = { min_lines = 5 }

      vim.api.nvim_win_set_cursor(0, { 20, 0 })

      assert.is_true(utils.should_show_lens(node_info, config))

      helper.cleanup_buffer(buf)
    end)
  end)
end)
