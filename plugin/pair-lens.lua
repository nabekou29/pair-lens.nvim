if vim.g.loaded_pair_lens then
  return
end
vim.g.loaded_pair_lens = true

vim.api.nvim_create_user_command("PairLensEnable", function()
  require("pair-lens").enable()
end, {
  desc = "Enable pair-lens globally",
})

vim.api.nvim_create_user_command("PairLensDisable", function()
  require("pair-lens").disable()
end, {
  desc = "Disable pair-lens globally",
})

vim.api.nvim_create_user_command("PairLensToggle", function()
  require("pair-lens").toggle()
end, {
  desc = "Toggle pair-lens globally",
})
