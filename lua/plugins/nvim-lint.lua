local M = {
  "mfussenegger/nvim-lint",
  event = "VeryLazy",
}

function M.config()
  require("lint").linters_by_ft = {
    -- go = { "golangcilint" },
    -- css = { "stylelint" },
    -- scss = { "stylelint" },
    -- less = { "stylelint" },
    -- sass = { "stylelint" },
    -- javascript = { "eslint" },
    -- javascriptreact = { "eslint" },
    -- typescript = { "eslint" },
    -- typescriptreact = { "eslint" },
    -- astro = { "eslint" },
    -- python = { "mypy" },
    -- terraform = { "tflint" },
    -- tf = { "tflint" },
  }

  -- override the default golangcilint args because I get error
  -- "golangci-lint run: unknown flag: --show-stats
  -- maybe version golangci-lint
  -- TODO: check this again in the future with a different golagncli-lint version

  -- local golangcilint = require("lint").linters.golangcilint
  -- golangcilint.args = {
  --   "run",
  --   "--out-format",
  --   "json",
  --   function()
  --     return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
  --   end,
  -- }

  vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "BufWritePost" }, {
    callback = function()
      require("lint").try_lint()
    end,
  })
end

return M
