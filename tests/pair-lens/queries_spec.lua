local queries = require("pair-lens.queries")

-- nvim-treesitter provides no standalone parser for these, so their default
-- queries cannot be checked here.
local without_parser = {
  jsonc = true,
}

describe("queries", function()
  describe("default_queries", function()
    local langs = vim.tbl_keys(queries.default_queries)
    table.sort(langs)

    for _, lang in ipairs(langs) do
      if not without_parser[lang] then
        it("should parse the " .. lang .. " query", function()
          assert.is_true(
            vim.treesitter.language.add(lang),
            "parser for " .. lang .. " is not installed"
          )

          local ok, err = pcall(vim.treesitter.query.parse, lang, queries.default_queries[lang])
          assert.is_true(ok, err)
        end)
      end
    end
  end)
end)
