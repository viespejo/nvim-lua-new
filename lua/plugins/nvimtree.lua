local function my_on_attach(bufnr)
  local api = require("nvim-tree.api")

  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  -- default mappings
  api.config.mappings.default_on_attach(bufnr)

  -- remove a default
  vim.keymap.del("n", "<C-x>", { buffer = bufnr })
  vim.keymap.del("n", "R", { buffer = bufnr })
  vim.keymap.del("n", "<C-]>", { buffer = bufnr })
  vim.keymap.del("n", "<Tab>", { buffer = bufnr })
  -- custom mappings
  vim.keymap.set("n", "<C-s>", api.node.open.horizontal, opts("Open: Horizontal Split"))
  vim.keymap.set("n", "gr", api.tree.reload, opts("Refresh"))
  vim.keymap.set("n", "cd", api.tree.change_root_to_node, opts("CD"))
  vim.keymap.set("n", "<C-p>", api.node.open.preview, opts("Open Preview"))
end

return {
  "nvim-tree/nvim-tree.lua",
  event = "VeryLazy",
  config = function()
    require("nvim-tree").setup({
      on_attach = my_on_attach,
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
