local M = {
  "ibhagwan/fzf-lua",
  event = "VeryLazy",
  -- optional for icon support
  dependencies = { "nvim-tree/nvim-web-devicons" },
}

function M.set_cwd(pwd)
  if not pwd then
    pwd = vim.fn.expand("%:h")
  end
  if vim.loop.fs_stat(pwd) then
    vim.cmd("cd " .. pwd)
  end
end

function M.workdirs(opts)
  local fzf_lua = require("fzf-lua")

  if not opts then
    opts = {}
  end

  -- workdirs.lua returns a table of workdirs
  local ok, dirs = pcall(function()
    return require("utils.workdirs").get()
  end)
  if not ok then
    dirs = {}
  end

  local fzf_fn = function(cb)
    for i, entry in ipairs(dirs) do
      if i == 1 then -- cwd
        entry = fzf_lua.utils.ansi_codes.yellow(entry:sub(1, 1)) .. entry:sub(2)
      -- elseif i == 2 or i == 3 or i == 4 then -- stdpaths
      --   entry = fzf_lua.utils.ansi_codes.magenta(entry:sub(1, 1)) .. entry:sub(2)
      else
        entry = fzf_lua.utils.ansi_codes.blue(entry:sub(1, 1)) .. entry:sub(2)
      end
      cb(entry)
    end
    cb(nil)
  end

  opts.fzf_opts = {
    ["--no-multi"] = "",
    ["--prompt"] = "Workdirs❯ ",
    ["--preview-window"] = "hidden:right:0",
    ["--header-lines"] = "1",
  }

  opts.actions = {
    ["default"] = function(selected)
      require("utils.workdirs").PREV_CWD = vim.loop.cwd()
      local newcwd = vim.fs.normalize(selected[1]:match("[^ ]*$"))
      M.set_cwd(newcwd)
    end,
  }

  fzf_lua.fzf_exec(fzf_fn, opts)
end

function M.config()
  local fzf_lua = require("fzf-lua")
  -- calling `setup` is optional for customization
  fzf_lua.setup({
    { "default-title" },
    winopts = {
      split = "aboveleft new", -- open in a split instead?
      preview = {
        hidden = "hidden",
      },
    },
    -- files = {
    -- 	previewer = false,
    -- },
    fzf_colors = function()
      return {
        -- ["fg"] = { "fg", "Normal" },
        ["bg"] = { "bg", "Normal" },
        -- ["hl"] = { "fg", "Comment" },
        -- ["fg+"] = { "fg", "CursorLine" },
        -- ["bg+"] = { "bg", "CursorLine" },
        -- ["hl+"] = { "fg", "Statement" },
        -- ["info"] = { "fg", "PreProc" },
        -- ["prompt"] = { "fg", "Conditional" },
        -- ["pointer"] = { "fg", "Exception" },
        -- ["marker"] = { "fg", "Keyword" },
        -- ["spinner"] = { "fg", "Label" },
        -- ["header"] = { "fg", "Comment" },
        -- ["gutter"] = { "bg", "Normal" },
        -- ["scrollbar"] = { "fg", "WarningMsg" },
      }
    end,
    git = {
      status = {
        preview_pager = false,
      },
    },
  })

  local keymap = vim.keymap.set
  local opts = { noremap = true, silent = true, desc = "fzf-lua" }

  keymap("n", "<Space><Space>", ":FzfLua buffers<cr>", opts)
  keymap("n", "<Space>f", ":FzfLua filetypes<cr>", opts)
  keymap("n", "<Space>p", ":FzfLua git_files<cr>", opts)
  keymap("n", "<Space>s", ":FzfLua git_status<cr>", opts)
  keymap("n", "<Space>P", ":FzfLua files<cr>", opts)
  keymap("n", "<Space>n", function()
    fzf_lua.files({ cwd = vim.fn.stdpath("config") })
  end, opts)
  keymap("n", "<Space>o", ":FzfLua oldfiles<cr>", opts)
  keymap("n", "<Space>O", function()
    fzf_lua.oldfiles({ cwd_only = true })
  end, opts)
  keymap("n", "<Space>d", function()
    M.workdirs()
  end, opts)
  keymap("n", "<Space>:", ":FzfLua command_history<cr>", opts)
  keymap("n", "<Space>/", ":FzfLua search_history<cr>", opts)
  keymap("n", "<Space>h", ":FzfLua help_tags<cr>", opts)
  keymap("n", "<Space>l", ":FzfLua lines<cr>", opts)
  keymap("n", "<Space>L", ":FzfLua blines<cr>", opts)
  keymap("n", "<Space>m", ":FzfLua marks<cr>", opts)
  keymap("n", "<Space><tab>", ":FzfLua keymaps<cr>", opts)
  keymap("n", "<Space>c", ":FzfLua commands<cr>", opts)
  keymap("n", "<Space>G", ":FzfLua grep_cword<cr>", opts)
  keymap("n", "<Space>gg", ":FzfLua live_grep<cr>", opts)
  keymap("n", "<Space>gp", ":FzfLua grep resume=true<cr>", opts)
  keymap("n", "<Space>r", ":FzfLua resume<cr>", opts)
  keymap("n", "<Space>a", "<cmd>call aerial#fzf()<cr>", opts)
  keymap("n", "<Space>R", ":FzfLua registers<cr>", opts)
  keymap("n", "<Space>t", ":FzfLua diagnostics_workspace<cr>", opts)
end

return M
