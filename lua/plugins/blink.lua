return {
  {
    "saghen/blink.cmp",
    -- event = "InsertEnter",
    version = "*",
    config = function()
      vim.api.nvim_set_hl(0, "MyPmenuSel", { link = "Todo" })

      require("blink.cmp").setup({
        snippets = { preset = "luasnip" },
        -- signature = { enabled = true },
        sources = {
          default = { "lazydev", "lsp", "path", "snippets", "buffer" },
          providers = {
            lazydev = {
              name = "LazyDev",
              module = "lazydev.integrations.blink",
              score_offset = 100,
            },
            -- cmdline = {
            --   min_keyword_length = 2,
            -- },
          },
        },
        keymap = {
          ["<C-space>"] = {},
          ["<C-_>"] = { "show", "show_documentation", "hide_documentation" },
        },
        cmdline = {
          keymap = {
            preset = "default",
            ["<C-space>"] = {},
            ["<C-_>"] = { "show", "show_documentation", "hide_documentation" },
            ["<CR>"] = { "accept_and_enter", "fallback" },
          },
          -- completion = { menu = { auto_show = true } },
        },
        completion = {
          list = {
            selection = {
              preselect = false,
              auto_insert = true,
            },
          },
          menu = {
            auto_show = false,
            border = nil,
            scrolloff = 1,
            scrollbar = false,
            draw = {
              columns = {
                { "kind_icon" },
                { "label", "label_description", gap = 1 },
                { "kind" },
                { "source_name" },
              },
            },
            winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,CursorLine:MyPmenuSel,Search:None",
          },
          documentation = {
            window = {
              border = nil,
              scrollbar = false,
              winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc",
            },
            auto_show = true,
            auto_show_delay_ms = 500,
          },
        },
      })

      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
}
