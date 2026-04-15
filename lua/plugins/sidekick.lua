local function send_shift_enter()
  local chan = vim.bo.channel
  if chan > 0 then
    vim.api.nvim_chan_send(chan, "\27[13;2u")
  end
end

vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("SidekickFix", { clear = true }),
  callback = function()
    vim.keymap.set("t", "<S-CR>", send_shift_enter, { buffer = true })
  end,
})

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
          -- prompt = false,
        },
        split = {
          width = 0.6,
        },
      },
      picker = "fzf-lua",
      tools = {
        -- PI tool integration only. Keep command identity stable for Sidekick workflows.
        -- NOTE: tmux mux sessions can reuse stale env from an earlier process.
        -- If external editor behavior drifts, refresh via <leader>sd (close) and
        -- <leader>ss (select PI again) to spawn a session with current env values.
        pi = {
          cmd = { "pi" },
          env = {
            EDITOR = "/home/its32ve1/code/pi-config/scripts/pi-editor-context",
            VISUAL = "/home/its32ve1/code/pi-config/scripts/pi-editor-context",
            PI_EDITOR_OPEN_MODE = "nvim",
          },
        },
      },
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
      mode = { "n", "t", "x" },
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
