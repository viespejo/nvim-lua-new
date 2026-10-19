-- Run from the repository: nvim --headless -u NONE -l tests/treesitter-preparation.test.lua
local runtime = vim
local module = dofile(runtime.fn.getcwd() .. "/lua/config/treesitter.lua")
local cases = 0
local function check(name, options, expected_error)
  options = options or {}
  local state = { installed = false, updated = false, closed = false }
  local parsers = {}
  for _, language in ipairs(module.languages) do
    parsers[language] = { install_info = { revision = "fixture-revision" } }
  end
  local function task(operation)
    return {
      pwait = function()
        if options.timeout == operation then
          return false, "fixture timeout"
        end
        if options.failure == operation then
          return true, false
        end
        return true, true
      end,
      close = function()
        state.closed = true
      end,
    }
  end
  package.loaded["nvim-treesitter"] = {
    setup = function() end,
    install = function(languages, opts)
      assert(languages == module.languages and opts.max_jobs == 2)
      state.installed = true
      return task("install")
    end,
    update = function(languages, opts)
      assert(state.installed and languages == module.languages and opts.max_jobs == 2)
      state.updated = true
      return task("update")
    end,
  }
  package.loaded["nvim-treesitter.parsers"] = parsers
  _G.vim = {
    uv = {
      getuid = function()
        return options.root and 0 or 1000
      end,
    },
    fn = {
      executable = function(command)
        return command == options.missing_command and 0 or 1
      end,
      filereadable = function(path)
        if options.missing_receipt and path:find("parser-info", 1, true) then
          return 0
        end
        if options.missing_parser and path:find(".so", 1, true) then
          return 0
        end
        return 1
      end,
      readfile = function()
        return { options.wrong_revision and "different-revision" or "fixture-revision" }
      end,
    },
    treesitter = {
      language = {
        add = function()
          return not options.unloadable
        end,
      },
      query = {
        get = function()
          return not options.missing_query and {} or nil
        end,
      },
    },
  }
  local original_print = print
  _G.print = function() end
  local ok, failure = pcall(module.prepare)
  _G.vim = runtime
  _G.print = original_print
  if expected_error then
    assert(not ok and tostring(failure):find(expected_error, 1, true), name .. ": " .. tostring(failure))
  else
    assert(ok and state.installed and state.updated, name .. ": " .. tostring(failure))
  end
  if options.timeout then
    assert(state.closed, "timed-out task not cancelled")
  end
  if options.root or options.missing_command then
    assert(not state.installed)
  end
  if options.failure == "install" then
    assert(not state.updated)
  end
  cases = cases + 1
  print("ok " .. cases .. " - " .. name)
end
check("successful preparation checks every declared parser")
check("root rejected", { root = true }, "not root")
check("missing compiler rejected", { missing_command = "cc" }, "cc")
check("installation failure stops synchronization", { failure = "install" }, "installation failed")
check("revision synchronization failure propagated", { failure = "update" }, "synchronization failed")
check("timeout cancels task", { timeout = "install" }, "fixture timeout")
check("missing receipt rejected", { missing_receipt = true }, "missing revision receipt")
check("wrong revision rejected", { wrong_revision = true }, "revision mismatch")
check("missing binary rejected", { missing_parser = true }, "missing parser")
check("unloadable parser rejected", { unloadable = true }, "cannot be loaded")
check("missing query rejected", { missing_query = true }, "missing highlights query")
print(cases .. " parser-preparation tests passed; installer effects were mocked")
