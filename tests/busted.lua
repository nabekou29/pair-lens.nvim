vim.env.LAZY_STDPATH = ".tests"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

-- Setup lazy.nvim
require("lazy.minit").busted({
  spec = {
    "nvim-lua/plenary.nvim",
    { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate lua javascript typescript tsx json" },
    { dir = vim.uv.cwd(), opts = {} },
  },
})
