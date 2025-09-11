return {
  "numToStr/Navigator.nvim",
  config = function()
    require("Navigator").setup({
      disable_on_zoom = true,
      mux = "auto",
    })
  end,
  keys = {
    { "<c-h>", "<CMD>NavigatorLeft<CR>", mode = { "n", "x" }, desc = "Navigator Left" },
    { "<c-l>", "<CMD>NavigatorRight<CR>", mode = { "n", "x" }, desc = "Navigator Right" },
    { "<c-k>", "<CMD>NavigatorUp<CR>", mode = { "n", "x" }, desc = "Navigator Up" },
    { "<c-j>", "<CMD>NavigatorDown<CR>", mode = { "n", "x" }, desc = "Navigator Down" },
  },
}
