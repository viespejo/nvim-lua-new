return {
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "vtsls",
        "typescript-language-server",
        "golangci-lint",
        "js-debug-adapter",
        "terraformls",
        "tflint",
      },
    },
  },
}
