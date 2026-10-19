return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "main",
        config = function()
          require("nvim-treesitter-textobjects").setup({
            select = {
              lookahead = true,
              include_surrounding_whitespace = true,
              selection_modes = {},
            },
            move = { set_jumps = true },
          })

          local function attach(buf)
            local language = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
            if vim.bo[buf].buftype ~= "" or not language or not vim.treesitter.language.add(language) then
              return
            end
            local select = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["at"] = "@class.outer",
              ["it"] = "@class.inner",
              ["ac"] = "@call.outer",
              ["ic"] = "@call.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
              ["al"] = "@loop.outer",
              ["il"] = "@loop.inner",
              ["ai"] = "@conditional.outer",
              ["ii"] = "@conditional.inner",
              ["a/"] = "@comment.outer",
              ["i/"] = "@comment.inner",
              ["ab"] = "@block.outer",
              ["ib"] = "@block.inner",
              ["as"] = "@statement.outer",
              ["is"] = "@scopename.inner",
              ["aA"] = "@attribute.outer",
              ["iA"] = "@attribute.inner",
              ["aF"] = "@frame.outer",
              ["iF"] = "@frame.inner",
              ["iv"] = "@key-value",
            }
            for lhs, capture in pairs(select) do
              vim.keymap.set({ "x", "o" }, lhs, function()
                require("nvim-treesitter-textobjects.select").select_textobject(capture, "textobjects")
              end, { buffer = buf, silent = true })
            end

            local moves = {
              goto_next_start = {
                ["]]"] = "@function.outer",
                ["]m"] = "@class.outer",
                ["]v"] = "@key-value",
                ["]a"] = "@parameter.inner",
              },
              goto_next_end = {
                ["]["] = "@function.outer",
                ["]M"] = "@class.outer",
              },
              goto_previous_start = {
                ["[["] = "@function.outer",
                ["[m"] = "@class.outer",
                ["[v"] = "@key-value",
                ["[a"] = "@parameter.inner",
              },
              goto_previous_end = {
                ["[]"] = "@function.outer",
                ["[M"] = "@class.outer",
              },
            }
            for method, mappings in pairs(moves) do
              for lhs, capture in pairs(mappings) do
                vim.keymap.set({ "n", "x", "o" }, lhs, function()
                  require("nvim-treesitter-textobjects.move")[method](capture, "textobjects")
                end, { buffer = buf, silent = true })
              end
            end

            vim.keymap.set("n", "<leader>a", function()
              require("nvim-treesitter-textobjects.swap").swap_next("@parameter.inner")
            end, { buffer = buf, silent = true })
            vim.keymap.set("n", "<leader>A", function()
              require("nvim-treesitter-textobjects.swap").swap_previous("@parameter.inner")
            end, { buffer = buf, silent = true })
          end
          vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("WorkbenchTextobjects", { clear = true }),
            callback = function(args)
              attach(args.buf)
            end,
          })
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) then
              attach(buf)
            end
          end
        end,
      },
    },
    config = function()
      require("config.treesitter").setup()
    end,
  },
}
