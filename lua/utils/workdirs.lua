M = {}

M.DIRS = {
  vim.fn.stdpath("data"),
  vim.fn.stdpath("config"),
  vim.fn.stdpath("state"),
  "~/.dotfiles",
  "~/.dotfiles-local",
  "~/.config",
  "~/Documents",
  "~/code",
  "~/code/nvim",
  "~/code/employeex",
  "~/code/glove80-zmk-config",
  "~/code/nvim/codecompanion.nvim",
  "~/code/nvim/codecompanion-history.nvim",
  "~/code/nvim/codecompanion-filewise.nvim",
  "~/.test-nvim/config/nvim",
  "~/.test-nvim/local/share/nvim",
  "~/.test-nvim/local/state/nvim",
}

M.PREV_CWD = nil

M.get = function(noicons)
  local iconify = function(path, icon)
    return string.format("%s  %s", icon, path)
  end

  local dirs = {}
  local dedup = {}

  local add_entry = function(path, icon)
    if not path then
      return
    end
    local expanded = vim.fn.expand(path)
    if not vim.loop.fs_stat(expanded) then
      return
    end
    if dedup[expanded] ~= nil then
      return
    end
    path = vim.fn.fnamemodify(expanded, ":~")
    table.insert(dirs, noicons and path or iconify(path, icon or ""))
    dedup[expanded] = true
  end

  add_entry(vim.loop.cwd(), "")
  add_entry(M.PREV_CWD)

  for _, path in ipairs(M.DIRS) do
    add_entry(path)
  end

  return dirs
end

return M
