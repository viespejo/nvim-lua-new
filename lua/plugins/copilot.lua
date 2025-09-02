return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  config = function()
    local always_attach_filetypes = {
      markdown = true,
      help = false,
      gitcommit = true,
      gitrebase = false,
      -- codecompanion = true,
      cvs = false,
      yaml = true,
    }

    local copilot_should_attach = require("copilot.config.should_attach").default

    local should_attach = function(_, _)
      if vim.bo.filetype and always_attach_filetypes[vim.bo.filetype] then
        return true
      end
      return copilot_should_attach(_, _)
    end

    local filetypes = vim.deepcopy(always_attach_filetypes)
    filetypes["."] = false

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
      should_attach = should_attach,
    })

    vim.keymap.set(
      "n",
      "<leader><c-s>",
      ":lua require('copilot.suggestion').toggle_auto_trigger()<CR>",
      { noremap = true, silent = true }
    )
  end,
}
