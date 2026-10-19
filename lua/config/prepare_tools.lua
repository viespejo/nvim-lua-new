local M = {}

local tools = {
  { "golangci-lint", "golangci-lint" },
  { "js-debug-adapter", "js-debug-adapter" },
  { "lua-language-server", "lua-language-server" },
  { "stylelint", "stylelint" },
  { "tailwindcss-language-server", "tailwindcss-language-server" },
  { "terraform-ls", "terraform-ls" },
  { "tflint", "tflint" },
  { "typescript-language-server", "typescript-language-server" },
  { "vtsls", "vtsls" },
  { "prettier", "prettier" },
  { "shfmt", "shfmt" },
  { "stylua", "stylua" },
  { "gopls", "gopls" },
  { "goimports", "goimports" },
}

local json_package = "vscode-langservers-extracted"
local json_version = "4.10.0"
local timeout = 15 * 60 * 1000

local function command(argv)
  local result = vim.system(argv, { text = true }):wait(timeout)
  assert(result.code == 0, table.concat(argv, " ") .. ": " .. (result.stderr or "") .. (result.stdout or ""))
  return result.stdout
end

local function verify_package(package, executable)
  assert(package:is_installed(), package.name .. ": installation missing")
  local receipt = vim.fn.stdpath("data") .. "/mason/packages/" .. package.name .. "/mason-receipt.json"
  assert(vim.fn.filereadable(receipt) == 1, package.name .. ": missing receipt; inspect with :Mason")
  vim.json.decode(table.concat(vim.fn.readfile(receipt), "\n"))
  local binary = vim.fn.stdpath("data") .. "/mason/bin/" .. executable
  assert(vim.fn.executable(binary) == 1, package.name .. ": executable missing: " .. binary)
end

function M.prepare()
  assert((vim.uv or vim.loop).getuid() ~= 0, "Run tool preparation as the editor user, not root")
  for _, executable in ipairs({ "node", "npm", "go", "git", "curl", "unzip", "tar", "gzip" }) do
    assert(vim.fn.executable(executable) == 1, "Required on explicit PATH: " .. executable)
  end

  -- Keep JSON LSP in the user's npm runtime, not in Mason.
  local npm_root = vim.trim(command({ "npm", "root", "--global" }))
  local home = (vim.uv or vim.loop).os_homedir()
  assert(npm_root:sub(1, #home + 1) == home .. "/", "npm global root must be inside the editor user's home")
  local package_path = npm_root .. "/" .. json_package
  local package_json = package_path .. "/package.json"
  if vim.fn.filereadable(package_json) == 1 then
    local metadata = vim.json.decode(table.concat(vim.fn.readfile(package_json), "\n"))
    assert(metadata.version == json_version, json_package .. ": existing version differs; review manually")
    print("preserved npm " .. json_package .. "@" .. metadata.version)
  else
    assert(
      not (vim.uv or vim.loop).fs_lstat(package_path),
      json_package .. ": existing path has no readable metadata; review manually"
    )
    command({ "npm", "install", "--global", "--ignore-scripts", json_package .. "@" .. json_version })
    assert(vim.fn.filereadable(package_json) == 1, json_package .. ": installation missing")
    local metadata = vim.json.decode(table.concat(vim.fn.readfile(package_json), "\n"))
    assert(metadata.version == json_version, json_package .. ": installed version differs")
    print("installed npm " .. json_package .. "@" .. metadata.version)
  end
  assert(vim.fn.executable("vscode-json-language-server") == 1, "JSON server missing from explicit PATH")

  require("lazy").load({ plugins = { "mason.nvim" } })
  local registry = require("mason-registry")
  local missing = false
  for _, tool in ipairs(tools) do
    if not registry.is_installed(tool[1]) then
      missing = true
    end
  end
  if missing then
    local done, success = false, false
    registry.refresh(function(ok)
      success, done = ok, true
    end)
    assert(
      vim.wait(timeout, function()
        return done
      end, 50),
      "Mason registry refresh timed out"
    )
    assert(success, "Mason registry refresh failed; inspect :MasonLog")
  end

  -- Resolve package definitions once, before starting any installation.
  local packages = {}
  for _, tool in ipairs(tools) do
    packages[#packages + 1] = { package = registry.get_package(tool[1]), executable = tool[2] }
  end
  for _, tool in ipairs(packages) do
    local package = tool.package
    local outcome = "preserved"
    if not package:is_installed() then
      local done, success, failure = false, false, nil
      local handle = package:install({}, function(ok, result)
        success, failure, done = ok, result, true
      end)
      if not vim.wait(timeout, function()
        return done
      end, 50) then
        handle:terminate()
        vim.wait(5000, function()
          return done
        end, 50)
        error(package.name .. ": installation timed out; inspect :MasonLog before retrying")
      end
      assert(success, package.name .. ": " .. tostring(failure))
      outcome = "installed"
    end
    verify_package(package, tool.executable)
    print(outcome .. " mason " .. package.name)
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
