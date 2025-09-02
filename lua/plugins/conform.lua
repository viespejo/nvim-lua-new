local M = {
  "stevearc/conform.nvim",
  event = "VeryLazy",
}

local function format_on_save(bufnr)
  -- Disable with a global or buffer-local variable
  if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
    return {}, false
  end

  local default_lsp_fallback = true
  -- get value from buffer-local variable if it exists
  -- set variable if you want to always use LSP formatting ("always") even if formatter is available
  -- or never (false) if you want not to use LSP formatting if formatter is not available
  if vim.b[bufnr] and vim.b[bufnr].lsp_fallback then
    default_lsp_fallback = vim.b[bufnr].lsp_fallback
  end

  return { lsp_fallback = default_lsp_fallback }, true
end

function M.config()
  local slow_format_buffers = {}
  require("conform").setup({
    formatters_by_ft = {
      ["lua"] = { "stylua" },
      ["json"] = { "jq" },
      ["yaml"] = { "prettier" },
      ["markdown"] = { "prettier" },
      ["sh"] = { "shfmt", "shellcheck" },
    },
    format_on_save = function(bufnr)
      if slow_format_buffers[bufnr] then
        return
      end

      local fos, ok = format_on_save(bufnr)
      if not ok then
        return
      end

      local function on_format(err)
        if err and err:match("timeout$") then
          slow_format_buffers[bufnr] = true
        end
      end
      return vim.tbl_extend("force", fos, {
        timeout_ms = 500,
      }), on_format
    end,
    format_after_save = function(bufnr)
      if not slow_format_buffers[bufnr] then
        return
      end

      local fos, ok = format_on_save(bufnr)
      if not ok then
        return
      end

      return fos
    end,
    notify_on_error = true,
  })

  -- command to format the current buffer or selection
  vim.api.nvim_create_user_command("FormatConform", function(args)
    local range = nil
    if args.count ~= -1 then
      local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
      range = {
        start = { args.line1, 0 },
        ["end"] = { args.line2, end_line:len() },
      }
    end

    require("conform").format({ async = true, lsp_fallback = false, range = range })
  end, { range = true })

  -- set keymap to format the current buffer or selection
  vim.keymap.set(
    { "n", "v" },
    "<leader>fc",
    ":FormatConform<cr>",
    { noremap = true, desc = "Format using formatter in conform.nvim" }
  )

  -- command to disable autoformat-on-save
  vim.api.nvim_create_user_command("FormatOnSaveDisable", function(args)
    if args.bang then
      -- FormatDisable! will disable formatting just for this buffer
      vim.b["disable_autoformat"] = true
    else
      vim.g.disable_autoformat = true
    end
  end, {
    desc = "Disable autoformat-on-save",
    bang = true,
  })

  -- command to enable autoformat-on-save
  vim.api.nvim_create_user_command("FormatOnSaveEnable", function()
    vim.b["disable_autoformat"] = false
    vim.g.disable_autoformat = false
  end, {
    desc = "Re-enable autoformat-on-save",
  })

  -- set keymaps to enable/disable autoformat-on-save
  vim.keymap.set("n", "<leader>fe", ":FormatOnSaveEnable<cr>", { noremap = true, desc = "Enable autofomat-on-save" })
  vim.keymap.set("n", "<leader>fd", ":FormatOnSaveDisable!<cr>", { noremap = true, desc = "Disable autofomat-on-save" })
end

return M
