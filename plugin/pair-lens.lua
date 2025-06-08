if vim.g.loaded_pair_lens == 1 then
  return
end
vim.g.loaded_pair_lens = 1

if vim.fn.has("nvim-0.8") == 0 then
  vim.api.nvim_err_writeln("pair-lens.nvim requires Neovim 0.8+")
  return
end

