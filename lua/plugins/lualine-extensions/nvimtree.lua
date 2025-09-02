local M = {}

local function statusline()
	return " NvimTree"
end

M.sections = {
	lualine_a = { statusline },
}

M.filetypes = { "NvimTree" }

return M
