-- togle copilot attach for codecompanion filetypes
vim.keymap.set("n", "<leader>cc", function()
  local ok, command = pcall(require, "copilot.command")
  if not ok then
    vim.notify("Copilot not installed", vim.log.levels.ERROR)
    return
  end
  command.toggle({ force = true })
  vim.notify("Toggling Copilot attach", vim.log.levels.INFO)
end, { noremap = true, buffer = true, desc = "Copilot: toggle attach" })
