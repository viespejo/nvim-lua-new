-- Run from the repository: nvim --headless -u NONE -l tests/prepare-tools.test.lua
local runtime = vim
local root = runtime.fn.getcwd()
local module = dofile(root .. "/lua/config/prepare_tools.lua")
local cases = 0

local function fixture(options)
  options = options or {}
  local state = { installs = 0, npm_installs = 0, refreshes = 0, packages = {}, messages = {} }
  local metadata
  if not options.npm_absent then
    metadata = { version = options.npm_version or "4.10.0" }
  end
  local fake = {
    uv = {
      getuid = function()
        return options.root and 0 or 1000
      end,
      os_homedir = function()
        return options.system_prefix and "/other" or "/fixture"
      end,
      fs_lstat = function()
        return options.conflicting_path and {} or nil
      end,
    },
    json = runtime.json,
    trim = function(text)
      return text:match("^%s*(.-)%s*$")
    end,
    fn = {},
    api = {
      nvim_err_writeln = function(message)
        state.error = message
      end,
    },
    cmd = function(command)
      state.exit = command
    end,
  }
  fake.fn.executable = function(binary)
    if options.missing_command == binary or (options.missing_binary and binary:find("/mason/bin/", 1, true)) then
      return 0
    end
    return 1
  end
  fake.fn.stdpath = function()
    return "/fixture/data"
  end
  fake.fn.filereadable = function(path)
    if path:find("/package.json", 1, true) then
      return metadata and 1 or 0
    end
    return options.missing_receipt and 0 or 1
  end
  fake.fn.readfile = function(path)
    return { runtime.json.encode(path:find("/package.json", 1, true) and metadata or {}) }
  end
  fake.system = function(argv)
    return {
      wait = function()
        if options.npm_failure then
          return { code = 1, stderr = "npm fixture failure" }
        end
        if argv[2] == "root" then
          return { code = 0, stdout = "/fixture/npm\n" }
        end
        assert(argv[2] == "install" and argv[3] == "--global" and argv[4] == "--ignore-scripts")
        assert(argv[5] == "vscode-langservers-extracted@4.10.0")
        state.npm_installs = state.npm_installs + 1
        metadata = { version = "4.10.0" }
        return { code = 0, stdout = "" }
      end,
    }
  end
  fake.wait = function(_, predicate)
    return predicate()
  end
  local registry = {}
  registry.is_installed = function(name)
    return not options.fresh or (state.packages[name] and state.packages[name].installed) or false
  end
  registry.refresh = function(callback)
    state.refreshes = state.refreshes + 1
    callback(not options.registry_failure)
  end
  registry.get_package = function(name)
    assert(not state.packages[name], "Package resolved more than once")
    local package = { name = name, installed = not options.fresh }
    package.is_installed = function(self)
      return self.installed
    end
    package.install = function(self, _, callback)
      state.installs = state.installs + 1
      self.installed = not options.postcondition_failure and not options.install_failure
      if not options.timeout then
        callback(not options.install_failure, "fixture install result")
      end
      return {
        terminate = function()
          state.terminated = true
        end,
      }
    end
    state.packages[name] = package
    return package
  end
  package.loaded["lazy"] = { load = function() end }
  package.loaded["mason-registry"] = registry
  _G.vim = fake
  return state
end

local function check(name, options, expected_error, verify)
  local state = fixture(options)
  local original_print = print
  _G.print = function(message)
    state.messages[#state.messages + 1] = message
  end
  local ok, failure = pcall(module.prepare)
  _G.print = original_print
  _G.vim = runtime
  if expected_error then
    assert(not ok and tostring(failure):find(expected_error, 1, true), name .. ": " .. tostring(failure))
  else
    assert(ok, name .. ": " .. tostring(failure))
  end
  if verify then
    verify(state)
  end
  cases = cases + 1
  print("ok " .. cases .. " - " .. name)
end

check("satisfied inputs perform no installation or refresh", {}, nil, function(state)
  assert(state.installs == 0 and state.npm_installs == 0 and state.refreshes == 0)
  assert(#state.messages == 15)
end)
check("fresh inputs install approved tools", { fresh = true, npm_absent = true }, nil, function(state)
  assert(state.installs == 14 and state.npm_installs == 1 and state.refreshes == 1)
end)
check("root rejected", { root = true }, "not root")
check("explicit runtime required", { missing_command = "node" }, "Required on explicit PATH: node")
check("existing npm version preserved on conflict", { npm_version = "5.0.0" }, "review manually", function(state)
  assert(state.npm_installs == 0 and state.installs == 0)
end)
check("npm failure propagated", { npm_failure = true }, "npm fixture failure")
check(
  "registry failure stops installations",
  { fresh = true, registry_failure = true },
  "registry refresh failed",
  function(state)
    assert(state.installs == 0)
  end
)
check("installer failure propagated", { fresh = true, install_failure = true }, "fixture install result")
check("failed install postcondition rejected", { fresh = true, postcondition_failure = true }, "installation missing")
check("missing receipt requires review", { missing_receipt = true }, "missing receipt")
check("missing executable requires review", { missing_binary = true }, "executable missing")
check("timeout terminates owned handle", { fresh = true, timeout = true }, "installation timed out", function(state)
  assert(state.terminated)
end)
check("system npm prefix rejected", { system_prefix = true }, "inside the editor user's home")
check(
  "incomplete npm package preserved",
  { npm_absent = true, conflicting_path = true },
  "existing path has no readable metadata"
)
local state = fixture({ root = true })
module.run()
_G.vim = runtime
assert(state.exit == "cquit 1" and state.error:find("not root", 1, true))
print("ok 15 - command entry point reports nonzero failure")
print("15 tests passed; npm and Mason effects were mocked")
