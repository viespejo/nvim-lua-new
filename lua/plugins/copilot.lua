return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  config = function()
    local filetypes = {
      markdown = true,
      help = false,
      gitcommit = true,
      gitrebase = false,
      cvs = false,
      yaml = true,
      ["."] = false,
    }

    require("copilot").setup({
      panel = {
        enabled = true,
        auto_refresh = false,
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept = "<c-l>",
          accept_line = "<c-e>",
          accept_word = "<c-w>",
          next = "<c-j>",
          dismiss = "<c-h>",
          prev = "<c-k>",
          -- dismiss = "<c-q>",
        },
      },
      filetypes = filetypes,
      copilot_node_command = "node",
    })

    vim.keymap.set(
      "n",
      "<leader><c-s>",
      ":lua require('copilot.suggestion').toggle_auto_trigger()<CR>",
      { noremap = true, silent = true }
    )
  end,
}
