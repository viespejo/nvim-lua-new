-- Description: Open netrw in Oil current directory
vim.keymap.set("n", "<leader>e.", function()
  local oil = require("oil")
  local dir = oil.get_current_dir()
  if not dir then
    return
  end
  vim.cmd("silent Explore " .. vim.fn.fnameescape(dir))
end, { desc = "Open netrw in Oil current dir", silent = true, buffer = true })
