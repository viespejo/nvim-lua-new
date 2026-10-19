-- Run from the repository: nvim --headless -u NONE -i NONE -l tests/sidekick-editor.test.lua
local runtime = vim
local source = runtime.fn.getcwd() .. "/lua/plugins/sidekick.lua"
local cases = 0

local function load_spec(editor, vertex)
  local env = { PI_EDITOR = editor, TMUX_PANE = "%fixture" }
  for key, value in pairs(vertex or {}) do
    env[key] = value
  end
  _G.vim = {
    env = env,
    g = { pi_editor_owner_key = "fixture-owner" },
    api = {
      nvim_create_augroup = function()
        return 1
      end,
      nvim_create_autocmd = function() end,
    },
  }
  local ok, spec = pcall(dofile, source)
  _G.vim = runtime
  assert(ok, spec)
  return spec
end

for _, fixture in ipairs({
  { name = "portable fallback", expected = "pi-editor" },
  { name = "explicit override", editor = "/fixture/custom-pi-editor", expected = "/fixture/custom-pi-editor" },
}) do
  local spec = load_spec(fixture.editor)
  for _, tool in ipairs({ "pi", "claude" }) do
    local env = spec.opts.cli.tools[tool].env
    assert(env.EDITOR == fixture.expected, fixture.name .. ": EDITOR for " .. tool)
    assert(env.VISUAL == fixture.expected, fixture.name .. ": VISUAL for " .. tool)
    assert(env.PI_EDITOR_OPEN_MODE == "auto", "Preserve editor routing mode")
    assert(env.PI_EDITOR_OWNER_PANE == "%fixture", "Preserve owner pane routing")
    assert(env.PI_EDITOR_OWNER_KEY == "fixture-owner", "Preserve owner identity")
    cases = cases + 1
  end
  assert(spec.opts.cli.tools.pi.cmd[1] == "pi", "Keep Pi command identity unchanged")
end

local vertex_keys = { "VERTEXAI_PROJECT", "VERTEXAI_LOCATION", "GOOGLE_CLOUD_PROJECT", "GOOGLE_CLOUD_LOCATION" }
for _, fixture in ipairs({
  {},
  {
    VERTEXAI_PROJECT = "fixture-vertex-project",
    VERTEXAI_LOCATION = "fixture-vertex-region",
    GOOGLE_CLOUD_PROJECT = "fixture-google-project",
    GOOGLE_CLOUD_LOCATION = "fixture-google-region",
  },
}) do
  local spec = load_spec(nil, fixture)
  for _, key in ipairs(vertex_keys) do
    assert(spec.opts.cli.tools.pi.env[key] == (fixture[key] or false), "Forward or unset " .. key)
    assert(spec.opts.cli.tools.claude.env[key] == nil, "Do not change the unrelated Claude environment")
  end
  cases = cases + 1
end

print(string.format("PASS %d Sidekick editor/environment routing cases", cases))
