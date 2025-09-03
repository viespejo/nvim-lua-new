return {
  "nvim-mini/mini.nvim",
  event = "VeryLazy",
  config = function()
    local diff = require("mini.diff")
    diff.setup({
      -- Disabled by default
      source = diff.gen_source.none(),
    })

    require("mini.ai").setup({ n_lines = 500 })
    require("mini.surround").setup()
    require("mini.operator").setup()
    require("mini.comment").setup()
  end,
}
