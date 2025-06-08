local helper = require("tests.helper")

describe("config", function()
  setup(helper.setup)
  teardown(helper.teardown)
  before_each(helper.before_each)
  after_each(helper.after_each)

  local config

  before_each(function()
    package.loaded["pair-lens.config"] = nil
    config = require("pair-lens.config")
  end)

  describe("defaults", function()
    it("should have correct default values", function()
      assert.is_true(config.defaults.enabled)
      assert.equal("󰶢 (:{start_line}-{end_line}) {start_text}", config.defaults.style.format)
      assert.equal("Comment", config.defaults.style.hl)
      assert.equal(6, config.defaults.min_lines)
      assert.is_table(config.defaults.disable_filetypes)
      assert.is_table(config.defaults.custom_queries)
    end)
  end)

  describe("setup", function()
    it("should merge user options with defaults", function()
      local opts = {
        enabled = false,
        min_lines = 10,
      }

      local result = config.setup(opts)

      assert.is_false(result.enabled)
      assert.equal(10, result.min_lines)
      assert.equal("Comment", result.style.hl)
    end)

    it("should validate configuration", function()
      assert.has_error(function()
        config.setup({ enabled = "invalid" })
      end)
    end)
  end)

  describe("validate", function()
    it("should return true for valid config", function()
      assert.is_true(config.validate(config.defaults))
    end)

    it("should return false for invalid types", function()
      assert.is_false(config.validate({ enabled = "invalid" }))
      assert.is_false(config.validate({ min_lines = "invalid" }))
      assert.is_false(config.validate({ style = "invalid" }))
    end)
  end)

  describe("is_filetype_disabled", function()
    it("should check if filetype is disabled with empty defaults", function()
      config.setup()

      assert.is_false(config.is_filetype_disabled("help"))
      assert.is_false(config.is_filetype_disabled("lua"))
    end)

    it("should check if filetype is disabled with custom config", function()
      config.setup({ disable_filetypes = { "help", "terminal" } })

      assert.is_true(config.is_filetype_disabled("help"))
      assert.is_true(config.is_filetype_disabled("terminal"))
      assert.is_false(config.is_filetype_disabled("lua"))
    end)
  end)
end)

