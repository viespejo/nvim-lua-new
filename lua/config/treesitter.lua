local M = {}

M.languages = {
  "astro",
  "c",
  "go",
  "gomod",
  "gowork",
  "gosum",
  "http",
  "javascript",
  "json",
  "markdown",
  "markdown_inline",
  "bash",
  "python",
  "tsx",
  "typescript",
  "yaml",
  "lua",
}

local install_dir = vim.fn.stdpath("data") .. "/site"

function M.setup()
  assert(vim.fn.has("nvim-0.12") == 1, "This configuration requires Neovim 0.12 or later")
  require("nvim-treesitter").setup({ install_dir = install_dir })
  local expand = vim.fn.maparg("an", "x", false, true).callback
  local shrink = vim.fn.maparg("in", "x", false, true).callback
  assert(type(expand) == "function" and type(shrink) == "function", "Native node-selection mappings unavailable")

  local function attach(buf)
    if vim.bo[buf].buftype ~= "" then
      return
    end
    local language = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
    if not language or not vim.treesitter.language.add(language) then
      return
    end
    vim.treesitter.start(buf, language)
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    vim.keymap.set("x", "v", expand, { buffer = buf, silent = true, desc = "Select parent node" })
    vim.keymap.set("x", "<C-v>", shrink, { buffer = buf, silent = true, desc = "Select previous child node" })
  end

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("WorkbenchTreesitter", { clear = true }),
    callback = function(args)
      attach(args.buf)
    end,
  })
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      attach(buf)
    end
  end
end

local function complete(task, operation)
  local ok, result = task:pwait(15 * 60 * 1000)
  if not ok then
    task:close()
    error(operation .. ": " .. tostring(result))
  end
  assert(result == true, operation .. " failed; inspect :TSLog")
end

function M.prepare()
  assert((vim.uv or vim.loop).getuid() ~= 0, "Prepare parsers as the editor user, not root")
  for _, executable in ipairs({ "tree-sitter", "cc", "curl", "tar" }) do
    assert(vim.fn.executable(executable) == 1, "Parser prerequisite missing from PATH: " .. executable)
  end
  local treesitter = require("nvim-treesitter")
  treesitter.setup({ install_dir = install_dir })
  complete(treesitter.install(M.languages, { max_jobs = 2, summary = true }), "Parser installation")
  complete(treesitter.update(M.languages, { max_jobs = 2, summary = true }), "Parser revision synchronization")
  local parsers = require("nvim-treesitter.parsers")
  for _, language in ipairs(M.languages) do
    local revision = assert(parsers[language].install_info.revision, language .. ": missing source revision")
    local receipt = install_dir .. "/parser-info/" .. language .. ".revision"
    assert(vim.fn.filereadable(receipt) == 1, language .. ": missing revision receipt")
    assert(table.concat(vim.fn.readfile(receipt), "\n") == revision, language .. ": revision mismatch")
    assert(vim.fn.filereadable(install_dir .. "/parser/" .. language .. ".so") == 1, language .. ": missing parser")
    assert(vim.treesitter.language.add(language), language .. ": parser cannot be loaded")
    assert(vim.treesitter.query.get(language, "highlights"), language .. ": missing highlights query")
    print("ready parser " .. language .. " " .. revision)
  end
end

function M.run()
  local ok, failure = xpcall(M.prepare, debug.traceback)
  if not ok then
    vim.api.nvim_err_writeln(tostring(failure))
    vim.cmd("cquit 1")
  end
end

return M
