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

local pi_editor = vim.env.PI_EDITOR or "/home/its32ve1/code/pi-config/scripts/pi-editor"

return {
  "folke/sidekick.nvim",
  opts = {
    cli = {
      mux = {
        enabled = true,
        backend = "tmux",
        create = "terminal", -- "terminal", "window", "split"
        split = {
          vertical = true, -- vertical or horizontal split
          size = 0.6, -- size of the split (0-1 for percentage)
        },
      },
      win = {
        keys = {
          buffers = false,
          files = false,
          hide_n = { "q", "hide", mode = "n", desc = "hide the terminal window" },
          hide_ctrl_q = false,
          hide_ctrl_dot = false,
          hide_ctrl_z = false,
          prompt = false,
          stopinsert = false,
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
            EDITOR = pi_editor,
            VISUAL = pi_editor,
            PI_EDITOR_OWNER_PANE = vim.env.TMUX_PANE or "",
            PI_EDITOR_OWNER_KEY = tostring(vim.g.pi_editor_owner_key or ""),
            PI_EDITOR_OPEN_MODE = "auto", -- options: "auto", "nvr", "nvim" default to "auto"
            -- PI_GOOGLE_USER_AGENT="GeminiCLI/0.35.3/gemini-3.1-pro-preview (linux; x64; terminal) google-api-nodejs-client/9.15.1"
            -- HTTP_PROXY = "http://127.0.0.1:4141",
            -- HTTPS_PROXY = "http://127.0.0.1:4141",
            -- NODE_TLS_REJECT_UNAUTHORIZED = 0,
            -- PI_EDITOR_DEBUG = "1",
          },
        },
        claude = {
          cmd = { "claude" },
          env = {
            EDITOR = pi_editor,
            VISUAL = pi_editor,
            PI_EDITOR_OWNER_PANE = vim.env.TMUX_PANE or "",
            PI_EDITOR_OWNER_KEY = tostring(vim.g.pi_editor_owner_key or ""),
            PI_EDITOR_OPEN_MODE = "auto",
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
      mode = { "n", "t" },
    },
    {
      "<leader>ss",
      function()
        vim.schedule(function()
          require("sidekick.cli").select()
        end)
      end,
      mode = { "n", "t" },
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
      "<leader>si",
      function()
        require("sidekick.cli").prompt()
      end,
      mode = { "n", "x" },
      desc = "Sidekick Select Prompt",
    },
    {
      "<leader>sc",
      function()
        require("sidekick.cli").toggle({ name = "claude", focus = true })
      end,
      desc = "Sidekick Toggle Claude",
    },
    {
      "<leader>sp",
      function()
        require("sidekick.cli").toggle({ name = "pi", focus = true })
      end,
      desc = "Sidekick Toggle Pi",
    },
  },
}
