local fzf_lua, _ = pcall(require, "fzf-lua")

local function fzf_picker()
  if not fzf_lua then
    return ""
  end

  local info_string = vim.inspect(require("fzf-lua").get_info()["fnc"])
  return info_string:gsub('"', "")
end

local function fzf_statusline()
  -- return "FZF"
  return "󰶚 FZF"
end

local M = {}

M.sections = {
  lualine_a = { fzf_statusline },
  lualine_z = { fzf_picker },
}

M.filetypes = { "fzf" }

return M
