return {
  "akinsho/toggleterm.nvim",
  event = "VeryLazy",
  config = function()
    local Terminal = require("toggleterm.terminal").Terminal
    local lazygit = Terminal:new({
      cmd = "lazygit",
      dir = "git_dir",
      direction = "float",
      float_opts = {
        border = "double",
      },
      -- function to run on opening the terminal
      on_open = function(term)
        vim.cmd("startinsert!")
        vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
      end,
      -- function to run on closing the terminal
      on_close = function()
        vim.cmd("startinsert!")
      end,
    })

    local lazygit_toggle = function()
      lazygit:toggle()
    end

    vim.keymap.set("n", "<leader>G", lazygit_toggle, { noremap = true, silent = true })
  end,
}
