local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }
local term_opts = { silent = true }
local command_opts = { noremap = true }

-- Modes
--   normal_mode = ""
--   insert_mode = "i",
--   visual_mode = "v",
--   visual_block_mode = "x",
--   term_mode = "t",
--   command_mode = "c",

-- NORMAL

-- Edit nvim config dir and file
keymap("n", "<leader>evv", [[:edit <c-r>=stdpath('config')<cr><cr>]], opts)
keymap("n", "<leader>evi", [[:edit <c-r>=stdpath('config')<cr>/init.lua<cr>]], opts)
keymap("n", "<leader>evu", [[:edit <c-r>=stdpath('config')<cr>/lua<cr>]], opts)
keymap("n", "<leader>evw", [[:edit <c-r>=stdpath('config')<cr>/lua/utils/workdirs.lua<cr>]], opts)

-- Delete buffer
keymap("n", "Q", ":bd<cr>", opts)
-- Delete all buffers except the current one
keymap("n", "<leader>bo", ":%bd|e#|bd#<cr>", opts)

-- Move text up and down
keymap("n", "<m-j>", "<esc>:m .+1<cr>==", opts)
keymap("n", "<m-k>", "<esc>:m .-2<cr>==", opts)

-- Better window navigation
keymap("n", "<leader>w", "<c-w>", opts)
-- keymap("n", "<c-h>", "<c-w>h", opts)
-- keymap("n", "<c-j>", "<c-w>j", opts)
-- keymap("n", "<c-k>", "<c-w>k", opts)
-- keymap("n", "<c-l>", "<c-w>l", opts)

-- Resize with arrows
keymap("n", "<m-Up>", ":resize -1<cr>", opts)
keymap("n", "<m-Down>", ":resize +1<cr>", opts)
keymap("n", "<m-Left>", ":vertical resize -1<cr>", opts)
keymap("n", "<m-Right>", ":vertical resize +1<cr>", opts)

-- Navigate buffers
keymap("n", "<m-n>", ":bn<cr>", opts)
keymap("n", "<m-p>", ":bp<cr>", opts)
keymap("n", "<leader>3", ":b#<cr>", opts)
keymap("n", "<leader>.", ":b#<cr>", opts)

-- Navigate tabs
keymap("n", "<m-h>", ":tabprevious<cr>", opts)
keymap("n", "<m-l>", ":tabnext<cr>", opts)

-- Open netwr on directory of the current file
keymap("n", "<leader>e.", ":e %:p:h<cr>", opts)
-- Open netwr on pwd directory
keymap("n", "<leader>ee", ":e.<cr>", opts)

-- nvimtree
keymap("n", "<Space>eo", ":NvimTreeToggle<cr>", opts)
keymap("n", "<Space>e.", ":NvimTreeOpen %:p:h<cr>", opts)
keymap("n", "<Space>ee", ":NvimTreeOpen .<cr>", opts)

-- helper to edit mode
keymap("n", "<leader>ew", ":e <c-r>=expand('%:h')<cr>", {})

-- toggle wrap
keymap("n", "<Space>w", ":set wrap!<cr>", opts)

-- toggle spell
keymap("n", "<Space>z", ":set spell!<cr>", opts)
keymap("n", "<leader>z", ":SpellCheck<cr>", opts)

-- quickfix and location list
keymap("n", "<leader>qo", ":copen<cr>", opts)
keymap("n", "<leader>qc", ":cclose<cr>", opts)
keymap("n", "<leader>qn", ":cnext<cr>zz", opts)
keymap("n", "<leader>qp", ":cprev<cr>zz", opts)
keymap("n", "<leader>qgg", ":cfirst<cr>zz", opts)
keymap("n", "<leader>qG", ":clast<cr>zz", opts)
keymap("n", "<leader>lo", ":lopen<cr>", opts)
keymap("n", "<leader>lc", ":lclose<cr>", opts)
keymap("n", "<leader>ln", ":lnext<cr>zz", opts)
keymap("n", "<leader>lp", ":lprev<cr>zz", opts)
keymap("n", "<leader>lgg", ":lfirst<cr>zz", opts)
keymap("n", "<leader>lG", ":llast<cr>zz", opts)

-- selecting text you just pasted
-- keymap("n", "gv", "'`[' . strpart(getregtype(), 0, 1) . '`]'", { noremap = true, expr = true })

-- turn highlighted matches off but it does not change hlsearch option
keymap("n", "<leader>/", ":nohlsearch<cr>", opts)

-- change Working Directory to that of the current file
keymap("n", "<leader>cd", ":lcd %:p:h<cr>", opts)

-- source current file
keymap("n", "<leader><leader>x", "<cmd>so %<CR>", opts)
keymap("n", "<leader>x", ":.lua<CR>", opts)
keymap("v", "<leader>x", ":lua<CR>", opts)

-- INSERT

-- i_ctrlx_ctrlf
keymap("i", "<c-f>", "<c-x><c-f>", { noremap = true })

-- VISUAL

-- Stay in indent mode
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up and down
keymap("v", "<m-j>", ":m .+1<cr>==", opts)
keymap("v", "<m-k>", ":m .-2<cr>==", opts)

-- trim leading whitespace
keymap("v", "<leader>S", ":s/^ //<cr>", { noremap = true })

-- copy whith losing register
-- keymap({ "x", "v" }, "p", [["_dP]])

-- VISUAL BLOCK

-- -- Move text up and down
keymap("x", "<m-j>", ":move '>+1<cr>gv-gv", opts)
keymap("x", "<c-k>", ":move '<-2<cr>gv-gv", opts)

-- COMMAND

-- change annoying typo in command mode
keymap("c", "Wq", "wq", command_opts)
keymap("c", "WQ", "wq", command_opts)

-- change Working Directory to that of the current file
keymap("c", "cd.", "lcd %:p:h", command_opts)

-- for when you forget to sudo.. Really Write the file.
keymap("c", "w!!", "w !sudo -S tee % >/dev/null", command_opts)

-- helper to edit mode
keymap("c", "%%", "<c-r>=expand('%:h')<cr>", command_opts)

-- TERMINAL

-- -- Better terminal navigation
keymap("t", "<c-q>", "<c-\\><c-n>", term_opts)
