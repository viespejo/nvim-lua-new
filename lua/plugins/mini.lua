return {
  enabled = false,
  "nvim-mini/mini.nvim",
  config = function()
    require("mini.statusline").setup({ use_icons = true })
    -- require("mini.diff").setup({
    --   -- Disabled by default
    --   source = diff.gen_source.none(),
    -- })
  end,
}
