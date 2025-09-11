return {
  "tpope/vim-fugitive",
  lazy = true,
  keys = {
    { "<leader>gs", "<cmd>Git<cr>", desc = "Fugitive" },
    { "<leader>gc", "<cmd>Git commit<cr>", desc = "Fugitive" },
    { "<leader>gd", "<cmd>Gdiffsplit<cr>", desc = "Fugitive Diff" },
    { "<leader>gb", "<cmd>Git blame<cr>", desc = "Fugitive Blame" },
    { "<leader>gl", "<cmd>Gclog<cr>", desc = "Fugitive Log" },
    { "<leader>gD", "<cmd>Gvdiffsplit!<cr>", desc = "Fugitive Diff Split" },
  },
  config = function()
    local opts = { noremap = true, silent = true, desc = "Fugitive" }
    local keymap = vim.api.nvim_set_keymap

    keymap("n", "<leader>gp", ":Git push<cr>", opts)
    keymap("n", "<leader>gr", ":Gread<cr>:GitGutter<cr>", opts)
    keymap("n", "<leader>gw", ":Gwrite<cr>:GitGutter<cr>", opts)
    keymap("n", "<leader>ge", ":Gedit<cr>", opts)

    -- Instead of reverting the cursor to the last position in the buffer, we
    -- set it to the first line when editing a git commit message
    vim.cmd([[
    augroup custom_fugitive
      autocmd!
      au FileType gitcommit au! BufEnter COMMIT_EDITMSG call setpos('.', [0, 1, 1, 0])
    augroup END
  ]])
  end,
}
