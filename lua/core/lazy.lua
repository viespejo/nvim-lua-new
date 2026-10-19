-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local uv = vim.uv or vim.loop
if not uv.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"
  local lock = vim.json.decode(table.concat(vim.fn.readfile(lockfile), "\n"))
  local commit = lock["lazy.nvim"] and lock["lazy.nvim"].commit
  assert(type(commit) == "string" and #commit == 40 and commit:match("^%x+$"), "Invalid lazy.nvim lockfile commit")
  vim.fn.mkdir(vim.fn.fnamemodify(lazypath, ":h"), "p")
  local staging = assert(uv.fs_mkdtemp(lazypath .. ".bootstrap-XXXXXX"))
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--no-checkout", lazyrepo, staging })
  if vim.v.shell_error == 0 then
    out = vim.fn.system({ "git", "-C", staging, "checkout", "--detach", commit })
  end
  local failure = vim.v.shell_error ~= 0 and out or nil
  if not failure then
    if uv.fs_lstat(lazypath) then
      failure = "Destination appeared during bootstrap; inspect it before retrying"
    else
      local moved, message = uv.fs_rename(staging, lazypath)
      if not moved then
        failure = message
      end
    end
  end
  if failure then
    vim.api.nvim_echo({
      { "Failed to bootstrap lazy.nvim:\n", "ErrorMsg" },
      { failure .. "\nStaging retained at " .. staging, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "plugins" },
  },
  dev = {
    path = "~/code/nvim",
  },
  rocks = {
    enabled = false,
  },
  install = {
    colorscheme = { "habamax" },
  },
  change_detection = {
    enabled = true,
    notify = false,
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
