return {
  "MeanderingProgrammer/render-markdown.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
  ft = { "codecompanion" },
  opts = {
    render_modes = true, -- Render in ALL modes
    sign = {
      enabled = false, -- Turn off in the status column
    },
    overrides = {
      filetype = {
        codecompanion = {
          html = {
            tag = {
              buf = { icon = " ", highlight = "CodeCompanionChatIcon" },
              file = { icon = " ", highlight = "CodeCompanionChatIcon" },
              group = { icon = " ", highlight = "CodeCompanionChatIcon" },
              help = { icon = "󰘥 ", highlight = "CodeCompanionChatIcon" },
              image = { icon = " ", highlight = "CodeCompanionChatIcon" },
              symbols = { icon = " ", highlight = "CodeCompanionChatIcon" },
              tool = { icon = "󰯠 ", highlight = "CodeCompanionChatIcon" },
              url = { icon = "󰌹 ", highlight = "CodeCompanionChatIcon" },
            },
          },
        },
      },
    },
  },
}
