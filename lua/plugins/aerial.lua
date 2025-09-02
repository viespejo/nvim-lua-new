local M = {
  "stevearc/aerial.nvim",
}

function M.aerial()
  local fzf_lua = require("fzf-lua")
  local aerial_fzf = require("aerial.fzf")

  local labels = aerial_fzf.get_labels()

  if labels == nil or next(labels) == nil then
    vim.notify("No symbols found", vim.log.levels.INFO)
    return
  end

  local opts = {}

  opts.fzf_opts = {
    ["--prompt"] = "Symbols❯ ",
    ["--layout"] = "reverse-list",
  }

  opts.actions = {
    ["default"] = function(selected)
      aerial_fzf.goto_symbol(selected[1])
    end,
  }

  fzf_lua.fzf_exec(labels, opts)
end

function M.config()
  require("aerial").setup({
    -- use on_attach to set keymaps when aerial has attached to a buffer
    on_attach = function(bufnr)
      vim.keymap.set("n", "<Space>a", M.aerial, { buffer = bufnr })
    end,
  })
  vim.keymap.set("n", "<Space>A", ":AerialToggle<cr>", { noremap = true, silent = true })
end

return M
