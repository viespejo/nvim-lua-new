local buf = vim.api.nvim_get_current_buf()
if vim.b[buf].go_ftplugin then
	return
end
vim.b[buf].go_ftplugin = true
-- vim.b[buf].lsp_fallback = "always"

local ok, dapgo = pcall(require, "dap-go")

if not ok then
	print("dap-go not found")
	return
end

vim.keymap.set("n", "<leader>dt", dapgo.debug_test, { noremap = true, silent = true, buffer = true })
