local M = {
	"folke/trouble.nvim",
	opts = {}, -- for default options, refer to the configuration section for custom setup.
	cmd = "Trouble",
	keys = {
		{
			"<leader>tt",
			"<cmd>Trouble diagnostics toggle<cr>",
			desc = "Diagnostics (Trouble)",
		},
	},
}

function M.config()
	require("trouble").setup({})
	vim.cmd([[au FileType Trouble setlocal statusline=\ \ Trouble]])
end

return M
