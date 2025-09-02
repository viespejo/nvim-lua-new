vim.cmd([[iabbrev <buffer> shb #!/bin/bash]])
vim.opt_local.makeprg = "chmod +x % && ./%"
vim.opt_local.errorformat = "%f: line %l: %m"
-- you can use :make to run the script or :make! to run the script and see the output
-- map <leader>r to :make
vim.keymap.set("n", "<leader>rr", ":make<CR>", { buffer = true, silent = true })
