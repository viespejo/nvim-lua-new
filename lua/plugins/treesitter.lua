return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = "VeryLazy",
    dependencies = {
      {
        -- "nvim-treesitter/playground",
        "nvim-treesitter/nvim-treesitter-textobjects",
      },
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "astro",
          "c",
          "go",
          "http",
          "javascript",
          "json",
          "markdown",
          "markdown_inline",
          "bash",
          "python",
          "tsx",
          "typescript",
          "yaml",
          "lua",
        },
        auto_install = false,
        highlight = {
          enable = true,
          -- disable = { "markdown" },
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<leader>v",
            node_incremental = "v",
            node_decremental = "<c-v>",
            scope_incremental = "<leader>v",
          },
        },
        indent = {
          enable = true,
        },
        -- playground = {
        -- 	enable = true,
        -- 	disable = {},
        -- 	updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
        -- 	persist_queries = false, -- Whether the query persists across vim sessions
        -- },
        textobjects = {
          select = {
            enable = true,
            -- Automatically jump forward to textobj, similar to targets.vim
            lookahead = true,
            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
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
            },
            include_surrounding_whitespace = true,
            selection_modes = {
              -- ["@parameter.outer"] = "v", -- charwise
              -- ["@function.outer"] = "V", -- linewise
              -- ["@class.outer"] = "<c-v>", -- blockwise
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ["<leader>a"] = "@parameter.inner",
            },
            swap_previous = {
              ["<leader>A"] = "@parameter.inner",
            },
          },
          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
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
          },
        },
      })
    end,
  },
}
