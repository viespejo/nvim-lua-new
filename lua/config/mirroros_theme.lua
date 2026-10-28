-- Optional MirrorOS highlight overrides. No user-controlled theme link is followed.
local M = {}
local path = "/usr/share/mirroros/themes/default/neovim.lua"
local uv = vim.uv or vim.loop
local bit = require("bit")

local function trusted_read(filename, owner, fs)
  local current = ""
  local parts = { "/" }
  for part in filename:gmatch("[^/]+") do
    current = current .. "/" .. part
    parts[#parts + 1] = current
  end
  local last
  for i, component in ipairs(parts) do
    local stat, err = fs.fs_lstat(component)
    if not stat then
      if err and err:match("ENOENT") then return nil, nil end
      return nil, "cannot inspect " .. component
    end
    local expected = i == #parts and "file" or "directory"
    if stat.type ~= expected or stat.uid ~= owner or bit.band(stat.mode, 18) ~= 0 then
      return nil, "untrusted " .. component
    end
    last = stat
  end
  local fd = fs.fs_open(filename, "r", 0)
  if not fd then return nil, "cannot open theme file" end
  local stat = fs.fs_fstat(fd)
  if not stat or stat.type ~= "file" or stat.uid ~= owner or bit.band(stat.mode, 18) ~= 0
    or stat.dev ~= last.dev or stat.ino ~= last.ino or stat.size > 65536 then
    fs.fs_close(fd)
    return nil, "theme file changed or is invalid"
  end
  local text = fs.fs_read(fd, stat.size, 0)
  fs.fs_close(fd)
  if not text or #text ~= stat.size then return nil, "cannot read theme file" end
  return text, nil
end

function M.apply()
  local ok, text, err = pcall(trusted_read, path, 0, uv)
  if not ok then
    vim.notify("MirrorOS theme: cannot inspect theme file", vim.log.levels.WARN)
    return
  end
  if err then
    vim.notify("MirrorOS theme: " .. err, vim.log.levels.WARN)
    return
  end
  if not text then return end
  local chunk, compile_error = loadstring(text, "@" .. path)
  if not chunk then
    vim.notify("MirrorOS theme: " .. tostring(compile_error), vim.log.levels.WARN)
    return
  end
  local applied, runtime_error = pcall(chunk)
  if not applied then vim.notify("MirrorOS theme: " .. tostring(runtime_error), vim.log.levels.WARN) end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("MirrorOSTheme", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = M.apply })
end

M._trusted_read = trusted_read
return M
