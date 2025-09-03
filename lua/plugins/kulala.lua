local M = {
  "mistweaverco/kulala.nvim",
  keys = {
    { "<leader>rs", desc = "Send request" },
    { "<leader>ra", desc = "Send all requests" },
    { "<leader>rb", desc = "Open scratchpad" },
  },
  ft = { "http", "rest" },
  opts = {
    global_keymaps = true,
    global_keymaps_prefix = "<leader>r",
    kulala_keymaps_prefix = "",
    additional_curl_options = {
      "--insecure",
    },
  },
}

vim.filetype.add({
  extension = {
    ["http"] = "http",
  },
})

return M
