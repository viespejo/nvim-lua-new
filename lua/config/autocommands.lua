local formatOptionsG = vim.api.nvim_create_augroup("vec_formatoptions", { clear = true })
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  group = formatOptionsG,
  callback = function()
    vim.cmd("set fo-=r fo-=o")
  end,
})

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
