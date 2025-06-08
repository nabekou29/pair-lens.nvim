if vim.g.loaded_pair_lens == 1 then
  return
end
vim.g.loaded_pair_lens = 1

vim.api.nvim_set_hl(0, "PairLensVirtualText", { link = "Comment", default = true })
