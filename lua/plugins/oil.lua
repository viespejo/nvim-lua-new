local M = {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
}

function M.config()
  local oil = require("oil")

  local function find_files()
    local dir = oil.get_current_dir()
    if vim.api.nvim_win_get_config(0).relative ~= "" then
      vim.api.nvim_win_close(0, true)
    end
    require("fzf-lua").files({ cwd = dir })
  end

  local function livegrep()
    local dir = oil.get_current_dir()
    if vim.api.nvim_win_get_config(0).relative ~= "" then
      vim.api.nvim_win_close(0, true)
    end
    require("fzf-lua").live_grep({ cwd = dir })
  end

  oil.setup({
    default_file_explorer = false,
    delete_to_trash = true,
    skip_confirm_for_simple_edits = false,
    prompt_save_on_select_new_entry = true,
    keymaps = {
      ["gd"] = {
        desc = "Toggle detail view - Oil",
        callback = function()
          local config = require("oil.config")
          if #config.columns == 1 then
            oil.set_columns({ "icon", "permissions", "size", "mtime" })
          else
            oil.set_columns({ "icon" })
          end
        end,
      },
      ["ff"] = {
        desc = "Find files - Oil",
        callback = find_files,
      },
      ["fg"] = {
        desc = "Live grep - Oil",
        callback = livegrep,
      },
    },
    view_options = {
      is_always_hidden = function(name)
        return name == ".."
      end,
    },
  })

  vim.keymap.set("n", "<leader>o.", oil.open, { desc = "Open parent directory - Oil" })
  vim.keymap.set("n", "<leader>oo", function()
    oil.open(vim.fn.getcwd())
  end, { desc = "Open cwd - Oil" })
end

return M
