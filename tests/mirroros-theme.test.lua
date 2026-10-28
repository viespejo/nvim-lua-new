vim.opt.runtimepath:prepend(vim.fn.getcwd())
local real_uv = vim.uv
local warnings = {}
local real_notify = vim.notify
vim.notify = function(message) warnings[#warnings + 1] = message end
local contents = "vim.g.mirroros_theme_test = (vim.g.mirroros_theme_test or 0) + 1"
local entries = {}
local components = { "/", "/usr", "/usr/share", "/usr/share/mirroros", "/usr/share/mirroros/themes", "/usr/share/mirroros/themes/default", "/usr/share/mirroros/themes/default/neovim.lua" }
for i, component in ipairs(components) do
  entries[component] = { type = i == #components and "file" or "directory", uid = 0, mode = 493, dev = 1, ino = i, size = #contents }
end
local fs = {}
function fs.fs_lstat(path) return entries[path], entries[path] and nil or "ENOENT" end
function fs.fs_open() return 42 end
function fs.fs_fstat() return entries[components[#components]] end
function fs.fs_read() return contents end
function fs.fs_close() end
vim.uv = fs
package.loaded["config.mirroros_theme"] = nil
local theme = require("config.mirroros_theme")
local function reset_file()
  entries[components[#components]] = { type = "file", uid = 0, mode = 420, dev = 1, ino = #components, size = #contents }
end
reset_file()
theme.setup()
theme.setup()
vim.cmd("doautocmd ColorScheme")
assert(vim.g.mirroros_theme_test == 1, "one callback per colorscheme")
vim.cmd("doautocmd ColorScheme")
assert(vim.g.mirroros_theme_test == 2, "colorscheme reload reapplies")
entries[components[#components]] = nil
theme.apply()
assert(#warnings == 0, "missing file must be silent")
reset_file()
entries["/usr/share"].mode = 511
theme.apply()
assert(#warnings == 1 and warnings[1]:match("untrusted"), "writable ancestor must be rejected")
entries["/usr/share"].mode = 493
entries["/usr/share"].uid = 1000
theme.apply()
assert(#warnings == 2, "untrusted owner must be rejected")
entries["/usr/share"].uid = 0
entries[components[#components]].type = "link"
theme.apply()
assert(#warnings == 3, "symlink must be rejected")
reset_file()
local original_fstat = fs.fs_fstat
fs.fs_fstat = function() local copy = vim.deepcopy(entries[components[#components]]); copy.ino = 99; return copy end
theme.apply()
assert(#warnings == 4, "replaced file must be rejected")
fs.fs_fstat = original_fstat
contents = "error('broken theme')"
reset_file()
theme.apply()
assert(#warnings == 5 and warnings[5]:match("broken theme"), "runtime error must warn")
contents = "not valid lua !"
reset_file()
theme.apply()
assert(#warnings == 6, "syntax error must warn")
local original_read = fs.fs_read
fs.fs_read = function() return nil end
theme.apply()
assert(#warnings == 7, "read failure must warn")
fs.fs_read = original_read
assert(vim.g.mirroros_theme_test == 2, "unsafe and broken files must not apply")
vim.uv = real_uv
vim.notify = real_notify
