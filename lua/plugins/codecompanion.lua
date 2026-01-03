local M = {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    { "ravitemer/codecompanion-history.nvim", dev = true }, -- Save and load conversation history
    "j-hui/fidget.nvim",
    {
      "ravitemer/mcphub.nvim", -- Manage MCP servers
      cmd = "MCPHub",
      build = "npm install -g mcp-hub@latest",
      config = function()
        require("mcphub").setup({
          --- `mcp-hub` binary related options-------------------
          config = vim.fn.expand("~/.config/mcphub/servers.json"), -- Absolute path to MCP Servers config file (will create if not exists)
          port = 37373, -- The port `mcp-hub` server listens to
          -- shutdown_delay = 60 * 10 * 000, -- Delay in ms before shutting down the server when last instance closes (default: 10 minutes)
          shutdown_delay = 0,
          mcp_request_timeout = 60000,
        })
      end,
    },
    { "dyamon/codecompanion-filewise.nvim", dev = true }, -- File-wise context, instructions, modes, and prompts
  },
  cmd = "CodeCompanionChat",
  keys = {
    { "<leader>ao", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "CodeCompanion Toggle" },
    { "<leader>aa", "<cmd>CodeCompanionChat<cr>", mode = { "n", "v" }, desc = "CodeCompanion" },
    { "<leader>ah", "<cmd>CodeCompanionHistory<cr>", mode = { "n" }, desc = "CodeCompanion History" },
  },
  dev = true,
}

function M.config()
  local fmt = string.format
  require("codecompanion").setup({
    extensions = {
      history = {
        enabled = true,
        opts = {
          picker = "fzf-lua",
          title_generation_opts = {
            adapter = "copilot",
            model = "gpt-4.1",
          },
          ---Enable detailed logging for history extension
          -- enable_logging = true,
          ---When chat is cleared with `gx` delete the chat from history
          delete_on_clearing_chat = true,
        },
      },
      mcphub = {
        callback = "mcphub.extensions.codecompanion",
        opts = {
          -- MCP Tools
          make_tools = true, -- Make individual tools (@server__tool) and server groups (@server) from MCP servers
          show_server_tools_in_chat = true, -- Show individual tools in chat completion (when make_tools=true)
          add_mcp_prefix_to_tool_names = false, -- Add mcp__ prefix (e.g `@mcp__github`, `@mcp__neovim__list_issues`)
          show_result_in_chat = true, -- Show tool results directly in chat buffer
          format_tool = nil, -- function(tool_name:string, tool: CodeCompanion.Agent.Tool) : string Function to format tool names to show in the chat buffer
          -- MCP Resources
          make_vars = true, -- Convert MCP resources to #variables for prompts
          -- MCP Prompts
          make_slash_commands = true, -- Add MCP prompts as /slash commands
        },
      },
      custom_memories = {
        enabled = false,
        opts = {},
      },
      mode = {
        enabled = false,
        opts = {},
      },
      custom_modes = {
        enabled = false,
        opts = {
          mode_dirs = {
            ".github/chatmodes",
            (vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. "/.config")) .. "/codecompanion/chatmodes",
          },
          model_map = {},
          tool_map = {
            problems = "#{lsp}",
          },
          format_content = function(body)
            return body:gsub("%f[#]#", "###")
          end,
          root_markers = { ".git", ".github" },
        },
      },
      custom_prompts = {
        enabled = false,
        opts = {
          prompt_dirs = {
            ".github/prompts",
            (vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. "/.config")) .. "/codecompanion/prompts",
          },
          prompt_role = "user",
          model_map = {},
          tool_map = {
            problems = "#{lsp}",
          },
          format_content = function(body)
            return body:gsub("%f[#]#", "###")
          end,
          root_markers = { ".git", ".github" },
        },
      },
    },
    adapters = {
      http = {
        opts = {
          show_presets = false,
          show_model_choices = true,
        },
        anthropic = require("codecompanion.adapters.http.anthropic"),
        openai = require("codecompanion.adapters.http.openai"),
        openai_responses = require("codecompanion.adapters.http.openai_responses"),
        copilot = function()
          return require("codecompanion.adapters").extend("copilot", {
            schema = {
              reasoning_effort = {
                mapping = "parameters",
                type = "string",
                optional = true,
                enabled = function(self)
                  local model = self.model.name:lower()
                  if type(model) == "function" then
                    model = model()
                  end
                  if model:find("gpt-5", 1, true) or model:find("gemini-", 1, true) then
                    return true
                  end
                  return false
                end,
                default = "minimal", -- high|medium|low|minimal
                desc = "Constrains effort on reasoning for reasoning models. Reducing reasoning effort can result in faster responses and fewer tokens used on reasoning in a response.",
                choices = {
                  "high",
                  "medium",
                  "low",
                  "minimal",
                },
              },
            },
          })
        end,
        gemini_code_assist = function()
          return require("codecompanion.adapters").extend("gemini-code-assist", {
            env = {
              project_id = "tww-cx-rnd-prod",
            },
          })
        end,
        vertex = function()
          return require("codecompanion.adapters").extend("vertex", {
            env = {
              project_id = "tww-cx-rnd-prod",
            },
          })
        end,
        vertex_regional_us_central1 = function()
          return require("codecompanion.adapters.http").extend("vertex", {
            name = "vertex_regional_us_central1",
            formatted_name = "Vertex AI Regional US-Central1",
            url = "https://aiplatform.googleapis.com/v1/projects/${project_id}/locations/${region}/endpoints/openapi/chat/completions",
            env = {
              project_id = "tww-cx-rnd-prod",
              region = "us-central1",
            },
          })
        end,
        vertex_regional_us_south1 = function()
          return require("codecompanion.adapters.http").extend("vertex", {
            name = "vertex_regional_us_south1",
            formatted_name = "Vertex AI Regional US-South1",
            env = {
              project_id = "tww-cx-rnd-prod",
              region = "us-south1",
            },
            schema = {
              model = {
                default = "qwen/qwen3-coder-480b-a35b-instruct-maas",
                choices = {
                  ["qwen/qwen3-coder-480b-a35b-instruct-maas"] = { opts = { can_reason = true } },
                },
              },
            },
          })
        end,
        gemini = function()
          return require("codecompanion.adapters").extend("gemini", {
            env = {
              api_key = "GEMINI_API_KEY",
            },
          })
        end,
      },
      acp = {
        opts = {
          show_presets = false,
        },
        gemini_cli = function()
          return require("codecompanion.adapters").extend("gemini_cli", {
            commands = {
              flash = {
                "gemini",
                "--experimental-acp",
                "-m",
                "gemini-3-flash-preview",
              },
              pro = {
                "gemini",
                "--experimental-acp",
                "-m",
                "gemini-3-pro-preview",
              },
            },
            defaults = {
              -- auth_method = "gemini-api-key", -- "oauth-personal" | "gemini-api-key" | "vertex-ai"
              auth_method = "oauth-personal",
              -- auth_method = "vertex-ai",
            },
          })
        end,
      },
    },
    interactions = {
      chat = {
        adapter = {
          -- name = "copilot",
          -- model = "gpt-5-mini",
          name = "gemini_code_assist",
          model = "gemini-3-flash-preview",
        },
        -- adapter = "copilot",
        slash_commands = {
          ["buffer"] = {
            opts = {
              provider = "fzf_lua",
            },
            keymaps = {
              modes = {
                n = "<leader>bb",
              },
            },
          },
          ["file"] = {
            opts = {
              provider = "fzf_lua",
            },
            keymaps = {
              modes = {
                n = "<leader>ff",
              },
            },
          },
          ["image"] = {
            opts = {
              dirs = { vim.fn.expand("~/Pictures/") },
            },
          },
        },
        roles = {
          ---The header name for the LLM's messages
          ---@type string|fun(adapter: CodeCompanion.Adapter): string
          llm = function(adapter)
            -- model_name is adapter.model.name:lower() if it exists, else acp then "unknown model"
            local model_name = "unknown model"
            if adapter.model and adapter.model.name then
              model_name = adapter.model.name:lower()
            end
            return "CodeCompanion (" .. adapter.formatted_name .. " - " .. model_name .. ")"
          end,
          user = "VEC", -- The markdown header for your questions
        },
        tools = {
          groups = {
            ["neovim_files"] = {
              description = "Tools related to creating, reading and editing files using Neovim mcp server",
              prompt = "I'm giving you access to ${tools} to help you perform file operations",
              tools = {
                "neovim__write_file",
                "neovim__edit_file",
                "neovim__read_multiple_files",
              },
              opts = {
                collapse_tools = false,
              },
            },
          },
          opts = {
            wait_timeout = 3600000, -- Time in ms to wait for user decision
            system_prompt = {
              enabled = false,
            },
          },
        },
        opts = {
          undolevels = 100, -- Number of undolevels to use for chat edits
        },
      },
      inline = {
        -- adapter = {
        -- 	name = "copilot",
        -- 	model = "gpt-4.1",
        -- },
        adapter = "copilot",
      },
    },
    -- PROMPT LIBRARIES ---------------------------------------------------------
    prompt_library = {
      markdown = {
        dirs = {
          vim.fn.getcwd() .. "/.prompts", -- Can be relative
          vim.fn.stdpath("config") .. "/lua/codecompanion/prompts",
        },
      },
    },
    -- RULES OPTIONS -----------------------------------------------------------
    rules = {
      -- SpecKit = {
      --   description = "SpecKit memory files",
      --   parser = "claude",
      --   files = {
      --     ["specify"] = {
      --       description = "Specification memory for the specify prompt",
      --       files = {
      --         ".claude/commands/specify.md",
      --       },
      --     },
      --     ["plan"] = {
      --       description = "Specification memory for the plan prompt",
      --       files = {
      --         ".claude/commands/plan.md",
      --       },
      --     },
      --     ["tasks"] = {
      --       description = "Specification memory for the tasks prompt",
      --       files = {
      --         ".claude/commands/tasks.md",
      --       },
      --     },
      --   },
      -- },
      opts = {
        chat = {
          enabled = true,
        },
      },
    },
    display = {
      chat = {
        show_settings = false, -- Show LLM settings at the top of the chat buffer?
      },
      inline = {
        -- If the inline prompt creates a new buffer, how should we display this?
        layout = "buffer", -- vertical|horizontal|buffer
      },
      diff = {
        provider = "mini_diff",
      },
      action_palette = {
        opts = {
          show_preset_actions = true,
          show_preset_prompts = false,
          show_prompt_library_builtins = true,
        },
      },
    },
    -- GENERAL OPTIONS ----------------------------------------------------------
    opts = {
      -- log_level = "DEBUG", -- TRACE|DEBUG|ERROR|INFO
    },
  })

  local opts = { noremap = true, silent = true, desc = "CodeCompanion" }
  vim.api.nvim_set_keymap("n", "<leader>aa", "<cmd>CodeCompanionActions<cr>", opts)
  vim.api.nvim_set_keymap("v", "<leader>aa", "<cmd>CodeCompanionActions<cr>", opts)
  vim.api.nvim_set_keymap("n", "<leader>ao", "<cmd>CodeCompanionChat Toggle<cr>", opts)
  vim.api.nvim_set_keymap("v", "<leader>ai", "<cmd>CodeCompanionChat Add<cr>", opts)

  -- notifications
  require("utils.codecompanion-notifications"):init()
end

-- Expand 'cc' into 'CodeCompanion' in the command line
vim.cmd([[cab cc CodeCompanion]])

return M
