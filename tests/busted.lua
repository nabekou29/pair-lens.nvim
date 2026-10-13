vim.env.LAZY_STDPATH = ".tests"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

local default_queries = dofile(vim.uv.cwd() .. "/lua/pair-lens/queries.lua").default_queries

-- Setup lazy.nvim
require("lazy.minit").busted({
  spec = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-treesitter/nvim-treesitter",
      config = function()
        -- On a fresh .tests the default install dir does not exist at startup and is
        -- missing from 'runtimepath', so installed parsers would not be found. Passing
        -- install_dir explicitly makes nvim-treesitter add it to 'runtimepath'.
        require("nvim-treesitter").setup({
          install_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site"),
        })
        require("nvim-treesitter").install(vim.tbl_keys(default_queries)):wait(300000)
      end,
    },
    { dir = vim.uv.cwd(), name = "pair-lens.nvim", opts = {} },
  },
})
