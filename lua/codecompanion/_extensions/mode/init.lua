local M = {}

function M.setup(user_config)
  require("codecompanion._extensions.mode.config").setup(user_config or {})

  local ok, cc_config = pcall(require, "codecompanion.config")
  if not ok then
    return
  end

  -- add keymap to chat strategy keymaps
  local keymaps = require("codecompanion._extensions.mode.keymaps")
  cc_config.interactions.chat.keymaps = vim.tbl_deep_extend("force", cc_config.strategies.chat.keymaps, keymaps:setup())
end

-- Optional: Functions exposed via codecompanion.extensions.your_extension
M.exports = {}

return M
