-- Run with the normal configuration: nvim --headless -c 'luafile tests/treesitter.test.lua' -c qa
local ok, failure = xpcall(function()
  require("lazy").load({ plugins = { "mini.nvim", "aerial.nvim", "rainbow-delimiters.nvim", "emmet-vim" } })
  local checks = 0
  local buffers = {}
  local function passed(message)
    checks = checks + 1
    print("ok " .. checks .. " - " .. message)
  end
  local function buffer(filetype, lines)
    local buf = vim.api.nvim_create_buf(true, false)
    buffers[#buffers + 1] = buf
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = filetype
    return buf
  end
  local samples = {
    astro = { "---", 'const title = "Hello";', "---", "<h1>{title}</h1>" },
    c = { "int main(void) { return 0; }" },
    go = { "package main", "func main() {}" },
    gomod = { "module example.test/demo", "go 1.27.0" },
    gowork = { "go 1.27.0", "use ./demo" },
    gosum = { "example.test/module v1.0.0 h1:abc=" },
    http = { "GET https://example.test/", "" },
    javascript = { "function example(value) { return value + 1; }" },
    json = { '{ "example": [1, 2] }' },
    markdown = {
      "# Outer",
      "",
      "## Inner",
      "",
      "```lua",
      "local value = { 1, 2 }",
      "```",
      "",
      "```sh",
      'printf "%s\\n" hello',
      "```",
    },
    markdown_inline = { "**bold** and `code`" },
    bash = { "#!/bin/bash", 'printf "%s\\n" hello' },
    python = { "def example(value):", "    return value + 1" },
    tsx = { "const Example = () => <div>Hello</div>;" },
    typescript = { "function example(value: number): number { return value + 1; }" },
    yaml = { "example:", "  - value" },
    lua = { "local function example(value)", "  return value + 1", "end" },
  }
  local groups = {
    "highlights",
    "injections",
    "indents",
    "textobjects",
    "aerial",
    "rainbow-delimiters",
    "rainbow-blocks",
    "matchup",
    "locals",
    "folds",
  }
  for _, language in ipairs(require("config.treesitter").languages) do
    local buf = buffer("workbench_query", samples[language])
    local parser = vim.treesitter.get_parser(buf, language)
    local trees = parser:parse()
    assert(trees and trees[1], language .. ": no syntax tree")
    local path = vim.api.nvim_get_runtime_file("parser/" .. language .. ".so", false)[1]
    assert(
      path == vim.fn.stdpath("data") .. "/site/parser/" .. language .. ".so",
      language .. ": wrong parser precedence"
    )
    for _, group in ipairs(groups) do
      local query = vim.treesitter.query.get(language, group)
      if query then
        for _ in query:iter_matches(trees[1]:root(), buf, 0, -1) do
        end
      end
    end
    passed(language .. " parser and available consumer queries")
  end

  local lua_lines = {
    "local function example(first, second)",
    "  local result = first + second",
    "  return result",
    "end",
    "",
    "local function another(value)",
    "  return example(value, value)",
    "end",
  }
  local buf = buffer("lua", lua_lines)
  for _, mapping in ipairs({ { "af", "x" }, { "]m", "n" }, { "<leader>a", "n" } }) do
    local registered = vim.fn.maparg(mapping[1], mapping[2], false, true)
    assert(
      registered.buffer == 1 and type(registered.callback) == "function",
      mapping[1] .. ": local textobject mapping missing"
    )
  end
  vim.api.nvim_win_set_cursor(0, { 2, 18 })
  vim.cmd.normal({ "v", bang = true })
  local expand = vim.fn.maparg("v", "x", false, true)
  local shrink = vim.fn.maparg("<C-v>", "x", false, true)
  assert(expand.buffer == 1 and type(expand.callback) == "function", "visual v mapping missing")
  assert(shrink.buffer == 1 and type(shrink.callback) == "function", "visual Ctrl+V mapping missing")
  local function selection()
    return vim.json.encode({ vim.fn.getpos("v"), vim.api.nvim_win_get_cursor(0) })
  end
  expand.callback()
  local first = selection()
  expand.callback()
  local second = selection()
  assert(first ~= second, "node expansion did not grow selection")
  shrink.callback()
  assert(selection() == first, "node contraction did not restore previous selection")
  vim.cmd.normal({ vim.api.nvim_replace_termcodes("<Esc>", true, false, true), bang = true })
  assert(vim.fn.maparg("<leader>v", "x") == "", "scope-selection mapping still present")
  assert(vim.fn.maparg("<leader>v", "n") == "", "old selection-init mapping still present")
  passed("native visual v/Ctrl+V expansion and history contraction; scope mapping absent")

  vim.api.nvim_win_set_cursor(0, { 2, 18 })
  require("nvim-treesitter-textobjects.select").select_textobject("@function.outer", "textobjects")
  assert(vim.fn.mode():find("v"), "function textobject did not enter visual mode")
  assert(vim.fn.line("v") == 1 and vim.fn.line(".") >= 4, "function textobject range differs")
  vim.cmd.normal({ vim.api.nvim_replace_termcodes("<Esc>", true, false, true), bang = true })
  passed("function textobject selection")

  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
  assert(vim.api.nvim_win_get_cursor(0)[1] == 6, "next function navigation differs")
  passed("function navigation")

  vim.api.nvim_win_set_cursor(0, { 1, assert(lua_lines[1]:find("first", 1, true)) - 1 })
  require("nvim-treesitter-textobjects.swap").swap_next("@parameter.inner")
  vim.api.nvim_feedkeys("", "x", false)
  assert(
    vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]:find("example(second, first)", 1, true),
    "parameter swap failed"
  )
  passed("parameter swap")

  local markdown = buffer("markdown", samples.markdown)
  local parser = vim.treesitter.get_parser(markdown)
  parser:parse(true)
  assert(vim.treesitter.highlighter.active[markdown], "Markdown highlighting not active")
  assert(not package.loaded["nvim-treesitter.query_predicates"], "legacy query handlers loaded")
  vim.cmd.redraw()
  passed("Markdown highlighting and fenced injections without legacy query handlers")

  local html = buffer("html", { "<div><span>hello</span></div>" })
  vim.api.nvim_win_set_cursor(0, { 1, 12 })
  vim.treesitter.get_parser(html):parse()
  assert(require("emmet_utils").get_node_at_cursor() == "html", "Emmet native embedded-language detection failed")
  assert(vim.fn["emmet#expandWord"]("ul>li", "html", 0):find("<ul>", 1, true), "Emmet abbreviation expansion failed")
  passed("Emmet native node detection and HTML expansion")

  local attribute_line = '<div title="hello"></div>'
  buffer("html", { attribute_line })
  for _, mapping in ipairs({ { "aA", 'title="hello"' }, { "iA", "hello" } }) do
    vim.api.nvim_win_set_cursor(0, { 1, assert(attribute_line:find("hello", 1, true)) - 1 })
    vim.cmd.normal({ "v", bang = true })
    local registered = vim.fn.maparg(mapping[1], "x", false, true)
    assert(registered.buffer == 1 and type(registered.callback) == "function", mapping[1] .. ": mapping missing")
    registered.callback()
    local selected = table.concat(vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = "v" }), "\n")
    assert(vim.trim(selected) == mapping[2], mapping[1] .. ": attribute selection differs: " .. selected)
    vim.cmd.normal({ vim.api.nvim_replace_termcodes("<Esc>", true, false, true), bang = true })
  end
  passed("aA selects the complete HTML attribute while iA selects its value")

  local parserless = buffer("workbench_parserless", { "search results" })
  assert(not vim.treesitter.highlighter.active[parserless], "parserless buffer got a highlighter")
  assert(vim.fn.maparg("v", "x", false, true).buffer ~= 1, "parserless buffer got node-selection keys")
  passed("parserless buffer does not attach Treesitter")
  for _, buf in ipairs(buffers) do
    vim.bo[buf].modified = false
  end
  print(checks .. " Treesitter integration checks passed; attended GUI checks remain required")
end, debug.traceback)
if not ok then
  vim.api.nvim_err_writeln(tostring(failure))
  vim.cmd("cquit 1")
end
