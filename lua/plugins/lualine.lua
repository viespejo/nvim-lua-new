local M = {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = {
    "AndreM222/copilot-lualine",
  },
}

function M.config()
  local hide_in_width = function()
    return vim.fn.winwidth(0) > 80
  end

  local diff = {
    "diff",
    -- colored = false,
    -- symbols = { added = " ", modified = " ", removed = " " }, -- changes diff symbols
    cond = hide_in_width,
  }

  local diagnostics = {
    "diagnostics",
    -- sources = { "nvim_diagnostic" },
    -- sections = { "error", "warn" },
    symbols = { error = " ", warn = " " },
    colored = false,
    update_in_insert = false,
    cond = hide_in_width,
    -- always_visible = true,
  }

  local filetype = {
    function()
      local filetype = vim.bo.filetype
      local upper_case_filetypes = {
        "json",
        "jsonc",
        "yaml",
        "toml",
        "css",
        "scss",
        "html",
        "xml",
      }

      if vim.tbl_contains(upper_case_filetypes, filetype) then
        return filetype:upper()
      end

      return filetype
    end,
  }

  local branch = {
    "branch",
    -- icons_enabled = true,
    icon = "",
    cond = hide_in_width,
  }

  local mode = {
    "mode",
    fmt = function(str)
      return "-- " .. str .. " --"
    end,
  }

  local linter_nvim_lint = {
    function()
      local linters = require("lint").get_running()
      if #linters == 0 then
        return "󰦕"
      end
      return "󱉶 " .. table.concat(linters, ", ")
    end,
    cond = function()
      local linters = require("lint")._resolve_linter_by_ft(vim.bo.filetype)
      if #linters == 0 then
        return false
      end
      return true
    end,
    icon = "Linter:",
  }

  require("lualine").setup({
    options = {
      theme = "tokyonight",
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
      -- disabled_filetypes = { "NvimTree" },
      -- ignore_focus = { "NvimTree" },
    },
    sections = {
      lualine_a = { "mode" },
      -- lualine_b = { branch, diff, diagnostics },
      lualine_b = { branch },
      lualine_c = { "filename", "copilot" },
      lualine_x = {
        linter_nvim_lint,
        -- conform_formatters,
        -- lsp_server,
        "encoding",
        { "fileformat", icons_enabled = false },
        filetype,
        require("plugins.lualine-components.codecompanion"),
      },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = { "filename" },
      lualine_x = { "location" },
      lualine_y = {},
      lualine_z = {},
    },
    extensions = {
      "quickfix",
      "man",
      -- "fugitive",
      "oil",
      require("plugins.lualine-extensions.fzf"),
      require("plugins.lualine-extensions.nvimtree"),
      require("plugins.lualine-extensions.trouble"),
      -- "trouble",
      "mason",
      "lazy",
      -- "aerial",
      -- "nvim-dap-ui",
      -- "toggleterm",
    },
  })
end

return M
