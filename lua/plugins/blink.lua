return {
  {
    "saghen/blink.cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    version = "*",
    dependencies = {
      { "onsails/lspkind-nvim" },
    },
    config = function()
      vim.api.nvim_set_hl(0, "MyPmenuSel", { link = "Todo" })

      require("blink.cmp").setup({
        snippets = { preset = "luasnip" },
        signature = { enabled = true },
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
            border = "none",
            scrolloff = 1,
            scrollbar = false,
            draw = {
              columns = {
                { "label", "label_description", gap = 1 },
                { "kind_icon" },
                { "kind" },
                { "source_name" },
              },
              components = {
                kind_icon = {
                  text = function(ctx)
                    local icon = ctx.kind_icon
                    if vim.tbl_contains({ "Path" }, ctx.source_name) then
                      local dev_icon, _ = require("nvim-web-devicons").get_icon(ctx.label)
                      if dev_icon then
                        icon = dev_icon
                      end
                    else
                      icon = require("lspkind").symbolic(ctx.kind, {
                        mode = "symbol",
                      })
                    end

                    return icon .. ctx.icon_gap
                  end,

                  -- Optionally, use the highlight groups from nvim-web-devicons
                  -- You can also add the same function for `kind.highlight` if you want to
                  -- keep the highlight groups in sync with the icons.
                  highlight = function(ctx)
                    local hl = ctx.kind_hl
                    if vim.tbl_contains({ "Path" }, ctx.source_name) then
                      local dev_icon, dev_hl = require("nvim-web-devicons").get_icon(ctx.label)
                      if dev_icon then
                        hl = dev_hl
                      end
                    end
                    return hl
                  end,
                },
              },
            },
            winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,CursorLine:MyPmenuSel,Search:None",
          },
          documentation = {
            window = {
              -- border = "rounded",
              scrollbar = false,
              winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc",
            },
            -- auto_show = true,
            -- auto_show_delay_ms = 500,
          },
        },
        fuzzy = {
          sorts = {
            -- (optionally) always prioritize exact matches
            "exact",

            -- pass a function for custom behavior
            -- function(item_a, item_b)
            --   return item_a.score > item_b.score
            -- end,

            "score",
            "sort_text",
          },
        },
      })

      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
}
