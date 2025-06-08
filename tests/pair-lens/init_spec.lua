local helper = require("tests.helper")

describe("init", function()
  setup(helper.setup)
  teardown(helper.teardown)
  before_each(helper.before_each)
  after_each(helper.after_each)

  local pair_lens

  before_each(function()
    pair_lens = helper.setup_test_environment()
  end)

  describe("setup", function()
    it("should create client instance", function()
      assert.is_not_nil(pair_lens.get_client())
    end)

    it("should setup client with autocmds and commands", function()
      local client = pair_lens.get_client()
      assert.is_not_nil(client.autocmd_group)
      assert.is_not_nil(client.namespace)
    end)
  end)

  describe("client integration", function()
    it("should update buffer with virtual text for lua functions", function()
      local buf = helper.create_lua_function_buffer()
      local client = pair_lens.get_client()

      -- TreeSitterを待機
      helper.wait_for_treesitter()

      local ok, parser = pcall(vim.treesitter.get_parser, buf)
      if ok and parser then
        client:update_virtual_text_for_buffer(buf, parser)
      end
      helper.wait_for_debounce()

      -- endの行（0から始まるので6）
      local virtual_text = helper.get_virtual_text(buf, 6)
      assert.is_not_nil(virtual_text)

      helper.cleanup_buffer(buf)
    end)

    it("should clear virtual text when buffer is deleted", function()
      local buf = helper.create_lua_function_buffer()
      local client = pair_lens.get_client()

      local ok, parser = pcall(vim.treesitter.get_parser, buf)
      if ok and parser then
        client:update_virtual_text_for_buffer(buf, parser)
      end
      client:clear_buffer(buf)

      local virtual_text = helper.get_virtual_text(buf, 7)
      assert.is_nil(virtual_text)

      helper.cleanup_buffer(buf)
    end)
  end)

  describe("commands", function()
    it("should handle enable/disable commands", function()
      local client = pair_lens.get_client()

      client:disable()
      assert.is_false(require("pair-lens.config").is_enabled())

      client:enable()
      assert.is_true(require("pair-lens.config").is_enabled())
    end)

    it("should handle toggle command", function()
      local client = pair_lens.get_client()
      local config = require("pair-lens.config")

      local initial_state = config.is_enabled()
      client:toggle()
      assert.is_not_equal(initial_state, config.is_enabled())

      client:toggle()
      assert.equal(initial_state, config.is_enabled())
    end)
  end)
end)
