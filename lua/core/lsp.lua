vim.diagnostic.config({
  -- virtual_lines = { current_line = true }
  virtual_text = {
    spacing = 2,
    prefix = "●",
    format = function(diagnostic)
      return string.format("[%s] %s", diagnostic.source or "LSP", diagnostic.message:gsub("\n", " "))
    end,
  },
  float = {
    border = "rounded",
    format = function(diagnostic)
      return string.format("%s [%s]", diagnostic.message, diagnostic.code or diagnostic.source or "LSP")
    end,
  },
})

-- Keymaps for diagnostics
vim.keymap.set("n", "gl", "<cmd>lua vim.diagnostic.open_float()<CR>", { desc = "Open diagnostic float" })

vim.lsp.enable({
  "lua_ls",
  "jsonls",
  "gopls",
  "vtsls",
  -- "tsgo",
})

-- LSP ATTACH
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    -- If it is copilot, we don't need to set keymaps
    if client.name == "copilot" then
      return
    end

    local function map(mode, lhs, rhs, opts)
      local options = { noremap = true, silent = true, buffer = args.buf, desc = "LSP" }
      if opts then
        options = vim.tbl_extend("force", options, opts)
      end
      vim.keymap.set(mode, lhs, rhs, options)
    end

    -- keymaps
    map("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>")
    map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>")
    map("n", "K", '<cmd>lua vim.lsp.buf.hover({ border = "rounded" })<cr>')
    map("n", "gI", "<cmd>lua vim.lsp.buf.implementation()<cr>")
    map("n", "<c-s>", "<cmd>lua vim.lsp.buf.signature_help()<cr>")
    map("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<cr>")
    map("n", "<leader>qq", "<cmd>lua vim.lsp.buf.references()<cr>")
    map("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<cr>")
    map("v", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<cr>")
    map("n", "[d", '<cmd>lua vim.diagnostic.goto_prev({ border = "rounded" })<cr>')
    map("n", "]d", '<cmd>lua vim.diagnostic.goto_next({ border = "rounded" })<cr>')
    map("n", "<leader>ll", "<cmd>lua vim.diagnostic.setloclist()<cr>")
    map("n", "<leader>hh", "<cmd>lua vim.lsp.buf.document_highlight()<cr>")
    map("n", "<leader>H", "<cmd>lua vim.lsp.buf.clear_references()<cr>")
    vim.cmd([[ command! FormatLSP execute 'lua vim.lsp.buf.format()' ]])
    map("n", "<leader>fl", ":FormatLSP<cr>", { silent = false, desc = "Format using LSP" })
    map("v", "<leader>fl", ":FormatLSP<cr>", { silent = false, desc = "Format using LSP" })
  end,
})

-- LSP COMMANDS
vim.api.nvim_create_user_command("LspLog", function()
  vim.cmd(string.format("tabnew %s", vim.lsp.log.get_filename()))
end, {
  desc = "Opens the Nvim LSP client log.",
})

local complete_client = function(arg)
  return vim
    .iter(vim.lsp.get_clients())
    :map(function(client)
      return client.name
    end)
    :filter(function(name)
      return name:sub(1, #arg) == arg
    end)
    :totable()
end

local complete_config = function(arg)
  return vim
    .iter(vim.api.nvim_get_runtime_file(("lsp/%s*.lua"):format(arg), true))
    :map(function(path)
      local file_name = path:match("[^/]*.lua$")
      return file_name:sub(0, #file_name - 4)
    end)
    :totable()
end

vim.api.nvim_create_user_command("LspStart", function(info)
  local servers = info.fargs

  -- Default to enabling all servers matching the filetype of the current buffer.
  -- This assumes that they've been explicitly configured through `vim.lsp.config`,
  -- otherwise they won't be present in the private `vim.lsp.config._configs` table.
  if #servers == 0 then
    local filetype = vim.bo.filetype
    for name, _ in pairs(vim.lsp.config._configs) do
      local filetypes = vim.lsp.config[name].filetypes
      if filetypes and vim.tbl_contains(filetypes, filetype) then
        table.insert(servers, name)
      end
    end
  end

  vim.lsp.enable(servers)
end, {
  desc = "Enable and launch a language server",
  nargs = "?",
  complete = complete_config,
})

vim.api.nvim_create_user_command("LspRestart", function(info)
  local clients = info.fargs

  -- Default to restarting all active servers
  if #clients == 0 then
    clients = vim
      .iter(vim.lsp.get_clients())
      :map(function(client)
        return client.name
      end)
      :totable()
  end

  for _, name in ipairs(clients) do
    if vim.lsp.config[name] == nil then
      vim.notify(("Invalid server name '%s'"):format(name))
    else
      vim.lsp.enable(name, false)
    end
  end

  local timer = assert(vim.uv.new_timer())
  timer:start(500, 0, function()
    for _, name in ipairs(clients) do
      vim.schedule_wrap(function(x)
        vim.lsp.enable(x)
      end)(name)
    end
  end)
end, {
  desc = "Restart the given client",
  nargs = "?",
  complete = complete_client,
})

vim.api.nvim_create_user_command("LspStop", function(info)
  local clients = info.fargs

  -- Default to disabling all servers on current buffer
  if #clients == 0 then
    clients = vim
      .iter(vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() }))
      :map(function(client)
        return client.name
      end)
      :totable()
  end

  for _, name in ipairs(clients) do
    if vim.lsp.config[name] == nil then
      vim.notify(("Invalid server name '%s'"):format(name))
    else
      vim.lsp.enable(name, false)
    end
  end
end, {
  desc = "Disable and stop the given client",
  nargs = "?",
  complete = complete_client,
})

local function lsp_status()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  if #clients == 0 then
    print("󰅚 No LSP clients attached")
    return
  end

  print("󰒋 LSP Status for buffer " .. bufnr .. ":")
  print("─────────────────────────────────")

  for i, client in ipairs(clients) do
    print(string.format("󰌘 Client %d: %s (ID: %d)", i, client.name, client.id))
    print("  Root: " .. (client.config.root_dir or "N/A"))
    print("  Filetypes: " .. table.concat(client.config.filetypes or {}, ", "))

    -- Check capabilities
    local caps = client.server_capabilities
    local features = {}
    if caps.completionProvider then
      table.insert(features, "completion")
    end
    if caps.hoverProvider then
      table.insert(features, "hover")
    end
    if caps.definitionProvider then
      table.insert(features, "definition")
    end
    if caps.referencesProvider then
      table.insert(features, "references")
    end
    if caps.renameProvider then
      table.insert(features, "rename")
    end
    if caps.codeActionProvider then
      table.insert(features, "code_action")
    end
    if caps.documentFormattingProvider then
      table.insert(features, "formatting")
    end

    print("  Features: " .. table.concat(features, ", "))
    print("")
  end
end

vim.api.nvim_create_user_command("LspStatus", lsp_status, { desc = "Show detailed LSP status" })

local function check_lsp_capabilities()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  if #clients == 0 then
    print("No LSP clients attached")
    return
  end

  for _, client in ipairs(clients) do
    print("Capabilities for " .. client.name .. ":")
    local caps = client.server_capabilities

    local capability_list = {
      { "Completion", caps.completionProvider },
      { "Hover", caps.hoverProvider },
      { "Signature Help", caps.signatureHelpProvider },
      { "Go to Definition", caps.definitionProvider },
      { "Go to Declaration", caps.declarationProvider },
      { "Go to Implementation", caps.implementationProvider },
      { "Go to Type Definition", caps.typeDefinitionProvider },
      { "Find References", caps.referencesProvider },
      { "Document Highlight", caps.documentHighlightProvider },
      { "Document Symbol", caps.documentSymbolProvider },
      { "Workspace Symbol", caps.workspaceSymbolProvider },
      { "Code Action", caps.codeActionProvider },
      { "Code Lens", caps.codeLensProvider },
      { "Document Formatting", caps.documentFormattingProvider },
      { "Document Range Formatting", caps.documentRangeFormattingProvider },
      { "Rename", caps.renameProvider },
      { "Folding Range", caps.foldingRangeProvider },
      { "Selection Range", caps.selectionRangeProvider },
    }

    for _, cap in ipairs(capability_list) do
      local status = cap[2] and "✓" or "✗"
      print(string.format("  %s %s", status, cap[1]))
    end
    print("")
  end
end

vim.api.nvim_create_user_command("LspCapabilities", check_lsp_capabilities, { desc = "Show LSP capabilities" })

local function lsp_diagnostics_info()
  local bufnr = vim.api.nvim_get_current_buf()
  local diagnostics = vim.diagnostic.get(bufnr)

  local counts = { ERROR = 0, WARN = 0, INFO = 0, HINT = 0 }

  for _, diagnostic in ipairs(diagnostics) do
    local severity = vim.diagnostic.severity[diagnostic.severity]
    counts[severity] = counts[severity] + 1
  end

  print("󰒡 Diagnostics for current buffer:")
  print("  Errors: " .. counts.ERROR)
  print("  Warnings: " .. counts.WARN)
  print("  Info: " .. counts.INFO)
  print("  Hints: " .. counts.HINT)
  print("  Total: " .. #diagnostics)
end

vim.api.nvim_create_user_command("LspDiagnostics", lsp_diagnostics_info, { desc = "Show LSP diagnostics count" })

local function lsp_info()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  print("═══════════════════════════════════")
  print("           LSP INFORMATION          ")
  print("═══════════════════════════════════")
  print("")

  -- Basic info
  print("󰈙 Language client log: " .. vim.lsp.get_log_path())
  print("󰈔 Detected filetype: " .. vim.bo.filetype)
  print("󰈮 Buffer: " .. bufnr)
  print("󰈔 Root directory: " .. (vim.fn.getcwd() or "N/A"))
  print("")

  if #clients == 0 then
    print("󰅚 No LSP clients attached to buffer " .. bufnr)
    print("")
    print("Possible reasons:")
    print("  • No language server installed for " .. vim.bo.filetype)
    print("  • Language server not configured")
    print("  • Not in a project root directory")
    print("  • File type not recognized")
    return
  end

  print("󰒋 LSP clients attached to buffer " .. bufnr .. ":")
  print("─────────────────────────────────")

  for i, client in ipairs(clients) do
    print(string.format("󰌘 Client %d: %s", i, client.name))
    print("  ID: " .. client.id)
    print("  Root dir: " .. (client.config.root_dir or "Not set"))
    print("  Command: " .. table.concat(client.config.cmd or {}, " "))
    print("  Filetypes: " .. table.concat(client.config.filetypes or {}, ", "))

    -- Server status
    if client.is_stopped() then
      print("  Status: 󰅚 Stopped")
    else
      print("  Status: 󰄬 Running")
    end

    -- Workspace folders
    if client.workspace_folders and #client.workspace_folders > 0 then
      print("  Workspace folders:")
      for _, folder in ipairs(client.workspace_folders) do
        print("    • " .. folder.name)
      end
    end

    -- Attached buffers count
    local attached_buffers = {}
    for buf, _ in pairs(client.attached_buffers or {}) do
      table.insert(attached_buffers, buf)
    end
    print("  Attached buffers: " .. #attached_buffers)

    -- Key capabilities
    local caps = client.server_capabilities
    local key_features = {}
    if caps.completionProvider then
      table.insert(key_features, "completion")
    end
    if caps.hoverProvider then
      table.insert(key_features, "hover")
    end
    if caps.definitionProvider then
      table.insert(key_features, "definition")
    end
    if caps.documentFormattingProvider then
      table.insert(key_features, "formatting")
    end
    if caps.codeActionProvider then
      table.insert(key_features, "code_action")
    end

    if #key_features > 0 then
      print("  Key features: " .. table.concat(key_features, ", "))
    end

    print("")
  end

  -- Diagnostics summary
  local diagnostics = vim.diagnostic.get(bufnr)
  if #diagnostics > 0 then
    print("󰒡 Diagnostics Summary:")
    local counts = { ERROR = 0, WARN = 0, INFO = 0, HINT = 0 }

    for _, diagnostic in ipairs(diagnostics) do
      local severity = vim.diagnostic.severity[diagnostic.severity]
      counts[severity] = counts[severity] + 1
    end

    print("  󰅚 Errors: " .. counts.ERROR)
    print("  󰀪 Warnings: " .. counts.WARN)
    print("  󰋽 Info: " .. counts.INFO)
    print("  󰌶 Hints: " .. counts.HINT)
    print("  Total: " .. #diagnostics)
  else
    print("󰄬 No diagnostics")
  end

  print("")
  print("Use :LspLog to view detailed logs")
  print("Use :LspCapabilities for full capability list")
end

-- Create command
vim.api.nvim_create_user_command("LspInfo", lsp_info, { desc = "Show comprehensive LSP information" })
