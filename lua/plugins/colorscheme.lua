return {
  {
    "folke/tokyonight.nvim",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      local tokyo = require("tokyonight")
      local util = require("tokyonight.util")

      tokyo.setup({
        -- your configuration comes here
        -- or leave it empty to use the default settingqs
        style = "night", -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
        sidebars = { "qf", "help", "terminal", "lazy" }, -- Set a darker background on sidebar-like windows. For example: `["qf", "vista_kind", "terminal", "packer"]`
        -- Change the "hint" color to the "orange" color, and make the "error" color bright red
        on_colors = function(colors)
          colors.hint = colors.orange
          colors.error = "#ff0000"
        end,
        on_highlights = function(hl, c)
          local bg_highlight = util.blend(c.bg_highlight, 0.3, "#1a1b26")
          hl.CursorLine = {
            bg = bg_highlight,
          }
          hl.CursorLineNr = {
            fg = c.dark5,
            bold = true,
          }
          hl.ColorColumn = {
            bg = bg_highlight,
          }
          hl.FloatBorder = { bg = c.bg }
          hl.NormalFloat = hl.Normal
        end,
      })

      vim.cmd.colorscheme("tokyonight")
    end,
  },
}
