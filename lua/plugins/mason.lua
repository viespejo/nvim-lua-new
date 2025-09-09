return {
  {
    "williamboman/mason.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      ensure_installed = {
        "lua-language-server",
        "vtsls",
        "typescript-language-server",
        "golangci-lint",
        "js-debug-adapter",
      },
    },
  },
}
