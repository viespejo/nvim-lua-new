local M = {}

local function statusline()
	return " Trouble"
end

M.sections = {
	lualine_a = { statusline },
}

M.filetypes = { "Trouble" }

return M
