return {
  "nvim-mini/mini.nvim",
  event = "VeryLazy",
  config = function()
    local diff = require("mini.diff")
    diff.setup({
      -- Disabled by default
      source = diff.gen_source.none(),
    })

    -- require("mini.comment").setup()
    require("mini.ai").setup({ n_lines = 500 })
    require("mini.sessions").setup()
    -- require("mini.surround").setup()
    -- require("mini.operators").setup()

    local keymap = vim.keymap.set
    local opts = { noremap = true, silent = true, desc = "fzf-lua" }

    keymap("n", "<Space>S", function()
      MiniSessions.select()
    end, opts)
  end,
}
