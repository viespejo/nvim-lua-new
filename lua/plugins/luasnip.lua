return {
  "L3MON4D3/LuaSnip",
  event = "InsertEnter",
  dependencies = {
    "rafamadriz/friendly-snippets",
  },
  config = function()
    local ls = require("luasnip")
    local types = require("luasnip.util.types")

    ls.config.set_config({
      -- This tells LuaSnip to remember to keep around the last snippet.
      -- You can jump back into it even if you move outside of the selection
      history = false,

      -- This one is cool cause if you have dynamic snippets, it updates as you type!
      updateevents = "TextChanged,TextChangedI",

      -- Autosnippets:
      enable_autosnippets = true,

      -- Crazy highlights!!
      -- #vid3
      -- ext_opts = nil,
      ext_opts = {
        [types.choiceNode] = {
          active = {
            virt_text = { { " « ", "NonTest" } },
          },
        },
      },
    })

    -- <c-up> is my expansion key
    -- this will expand the current item or jump to the next item within the snippet.
    vim.keymap.set({ "i", "s" }, "<m-k>", function()
      if ls.expand_or_jumpable() then
        ls.expand_or_jump()
      end
    end, { silent = true })

    -- <c-j> is my jump backwards key.
    -- this always moves to the previous item within the snippet
    vim.keymap.set({ "i", "s" }, "<m-j>", function()
      if ls.jumpable(-1) then
        ls.jump(-1)
      end
    end, { silent = true })

    -- <c-l> is selecting within a list of options.
    -- This is useful for choice nodes (introduced in the forthcoming episode 2)
    vim.keymap.set("i", "<m-l>", function()
      if ls.choice_active() then
        ls.change_choice(1)
      end
    end)

    vim.cmd([[command! LuaSnipEdit :lua require("luasnip.loaders").edit_snippet_files()]])
    require("luasnip.loaders.from_vscode").lazy_load({ build = "make install_jsregexp" })
    require("luasnip.loaders.from_lua").lazy_load({ paths = vim.fn.stdpath("config") .. "/lua/snippets" })
    require("luasnip").filetype_extend("typescriptreact", { "html" })
  end,
}
