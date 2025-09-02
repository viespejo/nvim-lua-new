-- This file contains utility functions to get information about the current buffer: LSP clients, formatters, and linters.
-- The function show_info() creates a buffer with this information and opens a window with it.
-- Finally it sets buffer keymaps to close the opened window, and a global keymap to call show the information.

--[[
    Developer: Vicente Espejo
    License: MIT License
    Version: 1.0.0
    Description: Utility functions for buffer information (LSP clients, formatters, linters)
]]

local function get_lsp_info()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	local client_names = {}
	for _, client in ipairs(clients) do
		table.insert(client_names, client.name)
	end

	if #client_names == 0 then
		return "No Active Lsp"
	end

	return table.concat(client_names, ", ")
end

local function get_formatters_info()
	local msg = "No Active Formatters"

	local ok, conform = pcall(require, "conform")
	if not ok then
		return msg
	end

	local formatters = conform.list_formatters()
	-- { { name = "prettier" }, { name = "eslint" } }
	if #formatters == 0 then
		return msg
	end

	local formatters_names = {}
	for _, formatter in ipairs(formatters) do
		table.insert(formatters_names, formatter.name)
	end

	if #formatters_names == 0 then
		return msg
	end

	return table.concat(formatters_names, ", ")
end

local function get_linters_info()
	local ok, lint = pcall(require, "lint")
	if not ok then
		return "NvimLint not installed"
	end
	local linters = lint._resolve_linter_by_ft(vim.bo.filetype)
	if #linters == 0 then
		return "No Active Linters for this filetype"
	end

	return table.concat(linters, ", ")
end
local function show_info()
	local lines = {
		" LSP Active Clients: " .. get_lsp_info(),
		" Formatters: " .. get_formatters_info(),
		" Linters: " .. get_linters_info(),
	}

	-- create buffer and write lines
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].swapfile = false
	vim.bo[buf].buflisted = false
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false

	-- create window
	-- width based in the longest line
	local max_len = 0
	for _, line in ipairs(lines) do
		max_len = math.max(max_len, #line)
	end

	local height = #lines

	local win = vim.api.nvim_open_win(buf, false, {
		relative = "cursor",
		width = max_len + 1,
		height = height,
		row = -2,
		col = 5,
		style = "minimal",
		border = "rounded",
		focusable = false,
	})

	-- when cursor moves, close the new window
	vim.api.nvim_create_autocmd("CursorMoved", {
		callback = function()
			vim.api.nvim_win_close(win, true)
		end,
		once = true,
	})
end

vim.keymap.set("n", "<leader>i", show_info, { noremap = true, silent = true, desc = "LSP, Formatters, Linters Info" })
