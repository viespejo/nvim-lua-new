-- Run from the repository: nvim --headless -u NONE -i NONE -l tests/lazy-bootstrap.test.lua
local runtime = vim
local source = runtime.fn.getcwd() .. "/lua/core/lazy.lua"
local destination = "/fixture/data/lazy/lazy.nvim"
local revision = string.rep("a", 40)
local cases = 0

local function fixture(options)
  options = options or {}
  local state = { target = options.existing, stages = {}, commands = {}, next_stage = 0, setups = 0 }
  local function run()
    local fake = {
      uv = {},
      fn = {},
      v = { shell_error = 0 },
      json = runtime.json,
      api = {
        nvim_echo = function(chunks)
          state.diagnostic = chunks[2][1]
        end,
      },
      opt = {
        rtp = {
          prepend = function(_, path)
            assert(path == destination)
          end,
        },
      },
    }
    fake.uv.fs_stat = function(path)
      assert(path == destination)
      return state.target and {} or nil
    end
    fake.uv.fs_lstat = function(path)
      assert(path == destination)
      return (state.target or options.concurrent) and {} or nil
    end
    fake.uv.fs_mkdtemp = function(template)
      assert(template == destination .. ".bootstrap-XXXXXX")
      state.next_stage = state.next_stage + 1
      local path = destination .. ".bootstrap-" .. state.next_stage
      state.stages[path] = { complete = false }
      return path
    end
    fake.uv.fs_rename = function(from, to)
      assert(to == destination and not state.target)
      assert(state.stages[from].complete, "Never publish an incomplete checkout")
      if options.rename_failure then
        return nil, "fixture rename failure"
      end
      state.target = true
      state.stages[from] = nil
      return true
    end
    fake.fn.stdpath = function(kind)
      return "/fixture/" .. kind
    end
    fake.fn.fnamemodify = function(path, modifier)
      assert(path == destination and modifier == ":h")
      return "/fixture/data/lazy"
    end
    fake.fn.mkdir = function(path, flags)
      assert(path == "/fixture/data/lazy" and flags == "p")
    end
    fake.fn.readfile = function(path)
      assert(path == "/fixture/config/lazy-lock.json")
      return { runtime.json.encode({ ["lazy.nvim"] = { commit = options.invalid_lock and "bad" or revision } }) }
    end
    fake.fn.getchar = function() end
    fake.fn.system = function(argv)
      state.commands[#state.commands + 1] = argv
      if argv[2] == "clone" then
        assert(argv[4] == "--no-checkout")
        assert(argv[5] == "https://github.com/folke/lazy.nvim.git")
        assert(state.stages[argv[6]] and argv[6] ~= destination)
        fake.v.shell_error = options.clone_failure and 1 or 0
        return "fixture clone failure"
      end
      assert(argv[2] == "-C" and state.stages[argv[3]])
      assert(argv[4] == "checkout" and argv[5] == "--detach" and argv[6] == revision)
      if options.interrupted then
        error("fixture interruption")
      end
      fake.v.shell_error = options.checkout_failure and 1 or 0
      state.stages[argv[3]].complete = fake.v.shell_error == 0
      return "fixture checkout failure"
    end
    local original_lazy = package.loaded["lazy"]
    local original_exit = os.exit
    package.loaded["lazy"] = {
      setup = function()
        assert(state.target, "Lazy setup requires a published checkout")
        state.setups = state.setups + 1
      end,
    }
    os.exit = function(code)
      error("fixture exit " .. code)
    end
    _G.vim = fake
    local ok, failure = pcall(dofile, source)
    _G.vim = runtime
    os.exit = original_exit
    package.loaded["lazy"] = original_lazy
    return ok, tostring(failure)
  end
  return state, run, options
end

local function passed(name)
  cases = cases + 1
  print("ok " .. cases .. " - " .. name)
end

local state, run = fixture()
assert(run())
assert(state.target and state.setups == 1 and #state.commands == 2 and next(state.stages) == nil)
passed("publish only after the locked checkout succeeds")

state, run = fixture({ existing = true })
assert(run())
assert(state.next_stage == 0 and #state.commands == 0 and state.setups == 1)
passed("preserve an existing installation without Git commands")

for _, kind in ipairs({ "clone_failure", "checkout_failure", "interrupted" }) do
  local options
  state, run, options = fixture({ [kind] = true })
  local ok = run()
  assert(not ok and not state.target and state.setups == 0)
  local retained = destination .. ".bootstrap-1"
  assert(state.stages[retained], "Preserve failed staging for diagnosis")
  if kind ~= "interrupted" then
    assert(state.diagnostic:find(retained, 1, true))
  end
  options[kind] = false
  assert(run())
  assert(state.target and state.setups == 1 and state.next_stage == 2)
  assert(state.stages[retained], "Retry must not adopt or delete prior staging")
  passed(kind .. " leaves the destination absent and allows an independent retry")
end

for _, kind in ipairs({ "concurrent", "rename_failure" }) do
  state, run = fixture({ [kind] = true })
  assert(not run())
  assert(not state.target and state.setups == 0 and next(state.stages))
  passed(kind .. " stops publication without replacing another destination")
end

state, run = fixture({ invalid_lock = true })
assert(not run())
assert(#state.commands == 0 and state.next_stage == 0 and not state.target)
passed("reject an invalid lock before creating staging or invoking Git")
print(cases .. " bootstrap tests passed; Git and filesystem effects were mocked")
