return {
  "mfussenegger/nvim-dap",
  lazy = true,
  dependencies = {
    {
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
      "theHamsta/nvim-dap-virtual-text",
      -- golang dap
      "leoluz/nvim-dap-go",
      -- python dap
      "mfussenegger/nvim-dap-python",
    },
  },
  keys = {
    {
      "<leader>db",
      function()
        require("dap").toggle_breakpoint()
      end,
    },
    {
      "<leader>dB",
      function()
        require("dap").toggle_breakpoint(vim.fn.input("Breakpoint condition: "))
      end,
    },
    {
      "<leader>dc",
      function()
        require("dap").continue()
      end,
    },
  },
  config = function()
    local dapui = require("dapui")
    dapui.setup()

    local dap = require("dap")
    local widgets = require("dap.ui.widgets")

    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open({ reset = true })
    end
    dap.listeners.before.event_terminated["dapui_config"] = dapui.close
    dap.listeners.before.event_exited["dapui_config"] = dapui.close

    -- dap virtual text
    require("nvim-dap-virtual-text").setup({
      enabled = true, -- enable this plugin (the default)
      enabled_commands = true, -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
      highlight_changed_variables = true, -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
      highlight_new_as_changed = false, -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
      show_stop_reason = true, -- show stop reason when stopped for exceptions
      commented = true, -- prefix virtual text with comment string
      -- experimental features:
      virt_text_pos = "eol", -- position of virtual text, see `:h nvim_buf_set_extmark()`
      all_frames = false, -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
      virt_lines = false, -- show virtual lines instead of virtual text (will flicker!)
      virt_text_win_col = 80, -- position the virtual text at a fixed window column (starting from the first text column) ,
      -- e.g. 80 to position at column 80, see `:h nvim_buf_set_extmark()`
    })

    local opts = { noremap = true, silent = true }
    local keymap = vim.keymap.set

    keymap("n", "<leader>ds", function()
      dap.disconnect()
    end, opts)
    keymap("n", "<leader>dk", function()
      dap.up()
    end, opts)
    keymap("n", "<leader>dj", function()
      dap.down()
    end, opts)
    keymap("n", "<leader>dn", function()
      dap.step_over()
    end, opts)
    keymap("n", "<leader>di", function()
      dap.step_into()
    end, opts)
    keymap("n", "<leader>do", function()
      dap.step_out()
    end, opts)
    keymap("n", "<leader>dg", function()
      dap.run_to_cursor()
    end, opts)
    keymap("n", "<leader>d/", function()
      dapui.toggle()
    end, opts)
    keymap({ "n", "v" }, "<leader>de", function()
      dapui.eval()
    end, opts)
    keymap("n", "<leader>dv", function()
      widgets.centered_float(widgets.scopes)
    end, opts)
    keymap("n", "<leader>dl", ":DapVirtualTextForceRefresh<CR>", opts)

    -- ADAPTERS AND CONFIGURATIONS

    -- GO
    require("dap-go").setup({
      -- Additional dap configurations
      -- :help dap-configuration
      dap_configurations = {
        {
          type = "go",
          name = "Attach remote",
          mode = "remote",
          request = "attach",
        },
      },
      delve = {
        port = "38699",
      },
    })

    -- JAVASCRIPT / TYPESCRIPT
    for _, adapter in ipairs({ "pwa-node", "pwa-chrome" }) do
      dap.adapters[adapter] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "js-debug-adapter",
          args = { "${port}" },
        },
      }
    end

    for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
      dap.configurations[language] = {
        {
          type = "pwa-node",
          request = "launch",
          name = "Launch file",
          program = "${file}",
          cwd = "${workspaceFolder}",
          sourceMaps = true,
        },
        {
          type = "pwa-node",
          request = "attach",
          name = "Attach",
          processId = require("dap.utils").pick_process,
          cwd = "${workspaceFolder}",
          sourceMaps = true,
        },
        {
          type = "pwa-chrome",
          request = "launch",
          name = "Launch Chrome",
          url = function()
            local co = coroutine.running()
            return coroutine.create(function()
              vim.ui.input({
                prompt = "Enter URL: ",
                default = "http://localhost:3000",
              }, function(url)
                if url == nil or url == "" then
                  return
                else
                  coroutine.resume(co, url)
                end
              end)
            end)
          end,
          webRoot = "${workspaceFolder}",
          skipFiles = { "<node_internals>/**/*.js" },
          sourceMaps = true,
        },
        {
          type = "pwa-chrome",
          request = "attach",
          name = "Attach Chrome",
          port = function()
            local co = coroutine.running()
            return coroutine.create(function()
              vim.ui.input({
                prompt = "Enter Port: ",
                default = "9222",
              }, function(port)
                if port == nil or port == "" then
                  return
                else
                  coroutine.resume(co, port)
                end
              end)
            end)
          end,
          webRoot = "${workspaceFolder}",
          skipFiles = { "<node_internals>/**/*.js" },
          sourceMaps = true,
        },
      }
    end

    -- PYTHON
    local function get_python_path()
      -- try to find the active virtualenv
      local venv = os.getenv("VIRTUAL_ENV")
      if venv then
        return venv .. "/bin/python"
      end
      -- if there is no active virtualenv, use the system python
      return "/usr/bin/python"
    end
    require("dap-python").setup(get_python_path())
  end,
}
