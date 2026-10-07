local formatOptionsG = vim.api.nvim_create_augroup("vec_formatoptions", { clear = true })
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  group = formatOptionsG,
  callback = function()
    vim.cmd("set fo-=r fo-=o")
  end,
})

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- PI editor server publication
--
-- 1) Primary route in tmux: pane-local option @pi_editor_nvr_server
-- 2) Secondary route outside tmux: owner-key state file in stdpath('state')
--
-- This module is always loaded (non-lazy) to avoid missing lifecycle events.
local PI_EDITOR_PANE_OPTION = "@pi_editor_nvr_server"
local PI_EDITOR_STATE_SUBDIR = ".local/state/pi-editor/servers"

local function tmux_available()
  return vim.fn.executable("tmux") == 1
end

local function current_tmux_pane()
  local pane = vim.env.TMUX_PANE
  if type(pane) ~= "string" or pane == "" then
    return ""
  end
  return pane
end

local function tmux_exec(cmd)
  vim.fn.system(cmd)
  return vim.v.shell_error == 0
end

local function tmux_read_pane_option(pane, option_name)
  if pane == "" or option_name == "" then
    return ""
  end

  local out = vim.fn.system({ "tmux", "show-options", "-p", "-v", "-t", pane, option_name })
  if vim.v.shell_error ~= 0 then
    return ""
  end

  return vim.trim(out or "")
end

local function current_owner_key()
  local pane = current_tmux_pane()
  if pane ~= "" then
    return "tmux-pane:" .. pane
  end

  local tty = vim.fn.system({ "bash", "-lc", "tty 2>/dev/null" })
  if vim.v.shell_error == 0 then
    tty = vim.trim(tty or "")
    if tty ~= "" and tty ~= "not a tty" then
      return "tty:" .. tty
    end
  end

  local cwd = vim.loop.cwd() or vim.fn.getcwd()
  local real = vim.loop.fs_realpath(cwd) or cwd
  return "cwd:" .. vim.fn.sha256(real)
end

local function state_dir_path()
  return vim.fn.expand("~/" .. PI_EDITOR_STATE_SUBDIR)
end

local function state_file_path(owner_key)
  return state_dir_path() .. "/" .. vim.fn.sha256(owner_key) .. ".json"
end

local function write_owner_state(owner_key, server)
  if owner_key == "" or server == "" then
    return false, "owner key or server unavailable"
  end

  vim.fn.mkdir(state_dir_path(), "p")
  local payload = vim.json.encode({
    ownerKey = owner_key,
    server = server,
    pid = vim.fn.getpid(),
    updatedAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
  })

  local ok = pcall(vim.fn.writefile, { payload }, state_file_path(owner_key), "b")
  if not ok then
    return false, "state file write failed"
  end

  return true, "ok"
end

local function read_owner_state(owner_key)
  if owner_key == "" then
    return nil
  end

  local file = state_file_path(owner_key)
  if vim.fn.filereadable(file) ~= 1 then
    return nil
  end

  local ok, lines = pcall(vim.fn.readfile, file, "b")
  if not ok or type(lines) ~= "table" then
    return nil
  end

  local raw = table.concat(lines, "\n")
  local ok, decoded = pcall(vim.json.decode, raw)
  if not ok or type(decoded) ~= "table" then
    return nil
  end

  return decoded
end

local function cleanup_owner_state(owner_key)
  if owner_key == "" then
    return
  end

  local state = read_owner_state(owner_key)
  if type(state) ~= "table" then
    return
  end

  local current = tostring(state.server or "")
  local mine = tostring(vim.v.servername or "")
  if current == "" or mine == "" then
    return
  end

  -- Guarded cleanup: only delete if this Neovim instance still owns the server.
  if current ~= mine then
    return
  end

  pcall(vim.fn.delete, state_file_path(owner_key))
end

local function publish_pi_editor_server()
  local server = vim.v.servername
  if type(server) ~= "string" or server == "" then
    return false, "vim.v.servername unavailable"
  end

  local owner_key = current_owner_key()
  vim.g.pi_editor_owner_key = owner_key

  local state_ok, state_reason = write_owner_state(owner_key, server)

  local pane = current_tmux_pane()
  local pane_ok = false
  local pane_reason = "TMUX_PANE unavailable"
  if pane ~= "" and tmux_available() then
    pane_ok = tmux_exec({ "tmux", "set-option", "-p", "-t", pane, PI_EDITOR_PANE_OPTION, server })
    pane_reason = pane_ok and "ok" or "tmux set-option failed"
  elseif pane ~= "" then
    pane_reason = "tmux unavailable"
  end

  vim.g.pi_editor_last_published_server = server
  vim.g.pi_editor_last_published_pane = pane

  local ok = state_ok or pane_ok
  local reason = string.format(
    "state=%s(%s), pane=%s(%s)",
    state_ok and "ok" or "fail",
    state_reason,
    pane_ok and "ok" or "skip/fail",
    pane_reason
  )

  return ok, reason
end

local function cleanup_pi_editor_server()
  local pane = current_tmux_pane()
  if pane ~= "" and tmux_available() then
    local current = tmux_read_pane_option(pane, PI_EDITOR_PANE_OPTION)
    local mine = vim.v.servername
    if current ~= "" and mine ~= "" and current == mine then
      tmux_exec({ "tmux", "set-option", "-p", "-u", "-t", pane, PI_EDITOR_PANE_OPTION })
    end
  end

  local owner_key = tostring(vim.g.pi_editor_owner_key or current_owner_key())
  cleanup_owner_state(owner_key)
end

-- Export a stable owner key for Sidekick PI env injection.
vim.g.pi_editor_owner_key = current_owner_key()

local piEditorServerGroup = vim.api.nvim_create_augroup("PiEditorServerPublish", { clear = true })
vim.api.nvim_create_autocmd({ "VimEnter", "FocusGained" }, {
  group = piEditorServerGroup,
  callback = function()
    publish_pi_editor_server()
  end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = piEditorServerGroup,
  callback = function()
    cleanup_pi_editor_server()
  end,
})

-- Best-effort publish on startup in case VimEnter happened before lazy plugin
-- loading paths that might trigger PI flows.
publish_pi_editor_server()

pcall(vim.api.nvim_del_user_command, "PiEditorPublishServer")
vim.api.nvim_create_user_command("PiEditorPublishServer", function()
  local ok, reason = publish_pi_editor_server()
  if ok then
    vim.notify(
      "Published PI editor server for owner " .. tostring(vim.g.pi_editor_owner_key or "") .. " (" .. reason .. ")",
      vim.log.levels.INFO
    )
    return
  end

  vim.notify("Failed to publish PI editor server: " .. reason, vim.log.levels.WARN)
end, {})
