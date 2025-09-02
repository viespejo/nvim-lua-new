return {
  "mbbill/undotree",
  keys = { -- load the plugin only when using it's keybinding:
    { "<leader>u", vim.cmd.UndotreeToggle },
  },
}
