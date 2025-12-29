return {
  "folke/sidekick.nvim",
  opts = {
    cli = {
      mux = {
        enabled = true,
        backend = "tmux",
        -- create = "split",
        -- split = {
        --   vertical = true, -- vertical or horizontal split
        --   size = 0.6, -- size of the split (0-1 for percentage)
        -- },
      },
      win = {
        keys = {
          prompt = false,
        },
        split = {
          width = 0.6,
        },
      },
      picker = "fzf-lua",
    },
    nes = {
      enabled = false,
    },
  },
  keys = {
    {
      "<leader>so",
      function()
        require("sidekick.cli").toggle()
      end,
      desc = "Sidekick Toggle",
      mode = { "n", "t", "i", "x" },
    },
    {
      "<leader>ss",
      function()
        require("sidekick.cli").select()
      end,
      -- Or to select only installed tools:
      -- require("sidekick.cli").select({ filter = { installed = true } })
      desc = "Select CLI",
    },
    {
      "<leader>sd",
      function()
        require("sidekick.cli").close()
      end,
      desc = "Detach a CLI Session",
    },
    {
      "<leader>st",
      function()
        require("sidekick.cli").send({ msg = "{this}" })
      end,
      mode = { "x", "n" },
      desc = "Send This",
    },
    {
      "<leader>sf",
      function()
        require("sidekick.cli").send({ msg = "{file}" })
      end,
      desc = "Send File",
    },
    {
      "<leader>sv",
      function()
        require("sidekick.cli").send({ msg = "{selection}" })
      end,
      mode = { "x" },
      desc = "Send Visual Selection",
    },
    {
      "<leader>sp",
      function()
        require("sidekick.cli").prompt()
      end,
      mode = { "n", "x" },
      desc = "Sidekick Select Prompt",
    },
  },
}
