local yaml_parser = require("codecompanion._extensions.custom_memories.yaml_parser")

local M = {}

--- Parses YAML frontmatter from a markdown file and returns it as a Lua table.
---@param path string Path to the markdown file
---@param rest boolean Whether to return the rest of the file as well.
---@return table|nil Parsed YAML frontmatter as a table, or nil if not found or invalid
---@return table List of lines from the rest of the file if `rest` is true, otherwise an empty table
function M.parse(path, rest)
  local in_frontmatter = false
  local after_frontmatter = false
  local frontmatter = {}
  local body = {}
  for l in io.lines(path) do
    if l:match("^%-%-%-") then
      if not in_frontmatter then
        in_frontmatter = true
      elseif not after_frontmatter then
        after_frontmatter = true
      else
        if rest then
          table.insert(body, l)
        else
          break
        end
      end
    elseif in_frontmatter and not after_frontmatter then
      table.insert(frontmatter, l)
    elseif after_frontmatter then
      if rest then
        table.insert(body, l)
      else
        break
      end
    end
  end
  local ok, fm = pcall(yaml_parser.parse, table.concat(frontmatter, "\n"))
  if ok and type(fm) == "table" then
    return fm, body
  end
  return nil, body
end

return M
