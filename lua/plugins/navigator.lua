return {
  "numToStr/Navigator.nvim",
  config = function()
    require("Navigator").setup({
      disable_on_zoom = true,
      mux = "auto",
    })
  end,
  keys = {
    { "<c-h>", "<CMD>NavigatorLeft<CR>", mode = { "n" }, desc = "Navigator Left" },
    { "<c-l>", "<CMD>NavigatorRight<CR>", mode = { "n" }, desc = "Navigator Right" },
    { "<c-k>", "<CMD>NavigatorUp<CR>", mode = { "n" }, desc = "Navigator Up" },
    { "<c-j>", "<CMD>NavigatorDown<CR>", mode = { "n" }, desc = "Navigator Down" },
  },
}
