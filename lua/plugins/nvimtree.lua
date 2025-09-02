return {
  "nvim-tree/nvim-tree.lua",
  event = "VeryLazy",
  config = function()
    require("nvim-tree").setup({
      -- on_attach = my_on_attach,
      hijack_netrw = false,
      view = {
        width = {},
      },
      actions = {
        open_file = {
          quit_on_open = true,
        },
      },
      update_focused_file = {
        enable = true,
        -- update_cwd = false,
        -- ignore_list = {},
      },
      renderer = {
        root_folder_label = function(path)
          path = vim.fn.fnamemodify(path, ":~")
          local parent_path = vim.fn.fnamemodify(path, ":h")
          local last_dir = vim.fn.fnamemodify(path, ":t")
          return parent_path:gsub("([a-zA-Z])[a-z]+", "%1") .. "/" .. last_dir
        end,
        indent_markers = {
          enable = true,
          inline_arrows = true,
          icons = {
            corner = "└",
            edge = "│",
            item = "│",
            none = " ",
          },
        },
      },
    })

    vim.api.nvim_set_hl(0, "NvimTreeRootFolder", { fg = "#f7768e", bold = true })
  end,
}
