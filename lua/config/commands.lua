-- SPELL CHECK TO QUICKFIX LIST
local function spell_to_quickfix()
  -- Clear the quickfix list
  vim.fn.setqflist({})
  -- Get all lines from the current buffer
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  -- get buffer name

  -- Table to store spelling errors
  local errors = {}
  -- Iterate through all lines and search for spelling errors
  for lnum, line in ipairs(lines) do
    local col = 1
    while col <= #line do
      -- Get the next misspelled word
      local badword = vim.fn.spellbadword(line:sub(col))

      -- Get the buffer number
      local bufnr = vim.fn.bufnr("%")

      if badword[1] == "" then
        break
      end

      local from = line:find(badword[1], col, true)
      local to = from + #badword[1]

      if not from or from == 0 then
        break
      else
        -- Add error to the table
        table.insert(errors, {
          bufnr = bufnr,
          lnum = lnum,
          col = from,
          text = badword[1],
        })
        col = to
      end
    end
  end

  -- Place the errors in the quickfix list
  vim.fn.setqflist(errors)
end

-- Create the custom command to invoke the function spell_to_quickfix
vim.api.nvim_create_user_command("SpellCheck", function()
  spell_to_quickfix()
  vim.cmd("copen")
end, {})

local function sudo_write_with_terminal()
  if not vim.bo.modifiable then
    vim.notify("Buffer not modifiable", vim.log.levels.ERROR)
    return
  end

  local tmp = vim.fn.tempname()
  vim.cmd("write! " .. vim.fn.fnameescape(tmp))
  local target = vim.fn.expand("%:p")
  -- open a terminal to run sudo mv so the password prompt is interactive
  vim.api.nvim_command(
    "botright split | terminal sudo mv " .. vim.fn.shellescape(tmp) .. " " .. vim.fn.shellescape(target)
  )
  -- user will input password in terminal; after it's done they can close it
end

-- Create the custom command to invoke the function sudo_write_with_terminal
vim.api.nvim_create_user_command("Wsudo", function()
  sudo_write_with_terminal()
end, {})
