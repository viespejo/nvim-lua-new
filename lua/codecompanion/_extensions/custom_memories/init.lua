local M = {}

local Path = require("plenary.path")
local frontmatter = require("codecompanion._extensions.custom_memories.frontmatter")
local utils = require("codecompanion._extensions.custom_memories.utils")

---@class CustomMemoriesTriggers
---@field slash_file boolean Enable /file slash command trigger
---@field slash_buffer boolean Enable /buffer slash command trigger

---@class CustomMemoriesKeymaps
---@field sync_context string Normal-mode mapping to trigger context synchronization

---@class CustomMemoriesConfig
---@field files string[] List of instruction file/globs
---@field triggers CustomMemoriesTriggers Trigger configuration
---@field keymaps CustomMemoriesKeymaps Keymaps configuration
---@field root_markers string[] List of project root marker files or directories

--- @type CustomMemoriesConfig
M.config = {
  files = {
    ".github/instructions/*.instructions.md",
    (vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. "/.config")) .. "/codecompanion/instructions/*.instructions.md",
  },
  triggers = {
    slash_file = true,
    slash_buffer = true,
  },
  keymaps = {
    sync_context = "gi",
  },
  root_markers = { ".git", ".github" },
}
---Mapping from glob pattern to list of instruction file paths (simple and conditional)
---@type table<string, string[]>
local apply_map = {}

---Expand globs to files from project root.
---@param globs string[] List of glob patterns
---@param base_path string|nil Optional base path to determine project root
---@return string[] List of resolved file paths
local function expand_globs(globs, base_path)
  local results = {}
  local project_root = Path:new(utils.find_project_root(M.config.root_markers, base_path) or vim.fn.getcwd())
  for _, g in ipairs(globs) do
    local path = Path:new(g)
    if not path:is_absolute() then
      path = project_root / path
    end
    vim.list_extend(results, vim.fn.glob(path:absolute(), false, true))
  end
  return results
end

---Split comma-separated globs into a list.
---@param str string Comma-separated globs
---@return string[] List of trimmed glob patterns
local function split_globs(str)
  local out = {}
  for g in str:gmatch("[^,]+") do
    table.insert(out, vim.trim(g))
  end
  return out
end

---Match file path against a Unix-style glob pattern.
---@param path string File path
---@param glob string Glob pattern
---@return boolean True if path matches glob
local function matches_glob(path, glob)
  if vim.regex(vim.fn.glob2regpat(glob)):match_str(path) then
    return true
  end
  return false
end

---Build mapping of instruction files from config.
local function build_mapping()
  -- Reset always included files
  apply_map = {}

  -- Add conditional files to their respective globs
  for _, path in ipairs(expand_globs(M.config.files)) do
    local fm, _ = frontmatter.parse(path, false)
    if fm and fm.applyTo then
      for _, g in ipairs(split_globs(fm.applyTo)) do
        apply_map[g] = apply_map[g] or {}
        table.insert(apply_map[g], path)
      end
    end
  end
end

---Add relevant instruction files to the context for a given buffer.
---@param bufnr integer Buffer number
function M.sync_context(bufnr)
  -- Get current chat
  local chat = require("codecompanion.strategies.chat").buf_get_chat(bufnr)
  if not chat then
    return
  end
  -- Get project root
  local project_root = utils.find_project_root(M.config.root_markers)
  if not project_root then
    vim.notify("[CustomMemories] Are you inside a project workspace?", vim.log.levels.WARN)
    return
  end
  -- Gather current local/project context
  local ctx = {}
  for _, c in ipairs(chat.context_items or {}) do
    local file = c.path
    if not file and c.id then
      file = c.id:match("^<file>(.-)</file>$") or c.id:match("^<buf>(.-)</buf>$")
    end
    if file then
      -- if c.id and c.id:match("^<memory>") then
      --   -- Skip memories
      --   goto continue
      -- end
      local path = Path:new(Path:new(file):absolute())
      if vim.startswith(path.filename, project_root) then
        table.insert(ctx, path:make_relative(project_root))
      end
    end
    -- ::continue::
  end
  -- Gather instruction files to be added to the context
  local to_add = {}
  for _, c in ipairs(ctx) do
    for glob, files in pairs(apply_map) do
      if glob == "**" or matches_glob(c, glob) then
        for _, instr in ipairs(files) do
          local rel = Path:new(instr):make_relative(project_root)
          table.insert(to_add, rel)
        end
      end
    end
  end
  -- Finally add files
  require("codecompanion.strategies.chat.memory").add_to_chat({
    name = "copilot_custom_instructions",
    opts = {},
    parser = "claude",
    files = to_add,
  }, chat)
end

---Setup the CustomMemories extension.
---@param opts table|nil Optional configuration overrides
function M.setup(opts)
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts)
  end

  -- Build mapping between files/globs and instruction files
  build_mapping()

  -- User commands
  vim.api.nvim_create_user_command(
    "CustomMemoriesReload",
    build_mapping,
    { desc = "Refresh custom instruction file mapping" }
  )
  vim.api.nvim_create_user_command("CustomMemoriesContextSync", function(opts)
    M.sync_context(opts.args ~= "" and tonumber(opts.args) or vim.api.nvim_get_current_buf())
  end, { desc = "Sync custom instructions to context", nargs = "?" })

  -- Keymaps
  local keymaps = require("codecompanion.config").strategies.chat.keymaps
  keymaps.sync_context = {
    modes = {
      n = M.config.keymaps.sync_context,
    },
    description = "Add relevant instruction files to the context.",
    callback = function()
      M.sync_context(vim.api.nvim_get_current_buf())
    end,
  }

  -- Patch /file slash command to trigger context injection
  if M.config.triggers.slash_file then
    local ok, slash_file = pcall(require, "codecompanion.strategies.chat.slash_commands.file")
    if ok and slash_file and slash_file.output then
      local orig_output = slash_file.output
      slash_file.output = function(self, ...)
        orig_output(self, ...)
        local orig_opts = select(2, ...) or {}
        if orig_opts.pin then
          return
        end
        vim.schedule(function()
          if self.Chat and self.Chat.bufnr then
            M.sync_context(self.Chat.bufnr)
          end
        end)
      end
      vim.notify("[CustomMemories] Patched /file slash command")
    end
  end

  -- Patch /buffer slash command to trigger context injection
  if M.config.triggers.slash_buffer then
    local ok, slash_buffer = pcall(require, "codecompanion.strategies.chat.slash_commands.buffer")
    if ok and slash_buffer and slash_buffer.output then
      local orig_output = slash_buffer.output
      slash_buffer.output = function(self, ...)
        orig_output(self, ...)
        local orig_opts = select(2, ...) or {}
        if orig_opts.pin then
          return
        end
        vim.schedule(function()
          if self.Chat and self.Chat.bufnr then
            M.sync_context(self.Chat.bufnr)
          end
        end)
      end
      vim.notify("[CustomMemories] Patched /buffer slash command")
    end
  end
end

return M
