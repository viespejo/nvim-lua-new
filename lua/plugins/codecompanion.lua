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
    -- { "dyamon/codecompanion-filewise.nvim", dev = true }, -- File-wise context, instructions, modes, and prompts
    -- { "cairijun/codecompanion-agentskills.nvim", dev = true }, -- Agent skills extension
    { "viespejo/cc-adapter-gemini-code-assist.nvim", dev = true }, -- Gemini Code Assist adapter
    { "viespejo/cc-adapter-vertex-ai.nvim", dev = true }, -- Vertex AI adapter
    { "viespejo/cc-adapter-codex.nvim", dev = true }, -- Codex adapter
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
  local cc_config = require("codecompanion.config")
  local original_resolve_input = cc_config.interactions.chat.opts.resolve_input

  require("codecompanion").setup({
    extensions = {
      history = {
        enabled = true,
        opts = {
          picker = "fzf-lua",
          auto_generate_title = false,
          -- title_generation_opts = {
          --   adapter = "copilot",
          --   model = "gpt-4.1",
          -- },
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
      agentskills = {
        enabled = false,
        opts = {
          paths = {
            ".codecompanion/skills",
            -- { "~/.config/nvim/skills", recursive = true }, -- Recursive search
          },
          external_allowlist = { "_bmad", "docs" },
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
          -- mitmproxy settings
          -- mitmproxy --set listen_port=4141
          -- allow_insecure = true,
          -- proxy = "http://127.0.0.1:4141",
        },
        anthropic = require("codecompanion.adapters.http.anthropic"),
        openai = function()
          local adapter = require("codecompanion.adapters.http.openai_responses")
          adapter.schema.model.choices = {
            ["gpt-5.4"] = {
              formatted_name = "GPT-5.4",
              opts = {
                has_function_calling = true,
                has_vision = true,
                can_reason = true,
              },
            },
            ["gpt-5.3-codex"] = {
              formatted_name = "GPT-5.3 Codex",
              opts = {
                has_function_calling = true,
                has_vision = true,
                can_reason = true,
              },
            },
            ["gpt-5.1-codex-mini"] = {
              formatted_name = "GPT-5.1 Codex Mini",
              opts = {
                has_function_calling = true,
                can_reason = true,
              },
            },
            ["gpt-5-mini"] = {
              formatted_name = "GPT-5 Mini",
              opts = {},
            },
          }
          adapter.schema.model.default = "gpt-5.1-codex-mini"
          adapter.schema.top_p.enabled = function(self)
            local model = self.schema.model.default
            if type(model) == "function" then
              model = model()
            end
            vim.print("Checking if top_p should be enabled for model: " .. model)
            vim.print("It is gpt-5.4: " .. tostring(model:find("gpt%-5.4") and true or false))
            if model:find("gpt%-5.4") then
              return false
            end
            return true
          end
          return adapter
        end,
        copilot = function()
          return require("codecompanion.adapters").extend("copilot", {
            schema = {
              model = {
                default = "gpt-5-mini",
              },
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
        gemini_code_assist_work = function()
          return require("codecompanion.adapters").extend("gemini-code-assist", {
            formatted_name = "Gemini Code Assist Work",
            opts = {
              profile = "work",
            },
            env = {
              project_id = "tww-cx-rnd-prod",
            },
          })
        end,
        gemini_code_assist_personal = function()
          return require("codecompanion.adapters").extend("gemini-code-assist", {
            formatted_name = "Gemini Code Assist Personal",
            opts = {
              profile = "personal",
            },
            env = {
              -- project_id is not necessary (free tier)
            },
          })
        end,
        vertex_gemini = function()
          return require("codecompanion.adapters").extend("vertex-gemini", {
            formatted_name = "Vertex AI Gemini",
            env = {
              project_id = "tww-cx-rnd-prod",
            },
          })
        end,
        vertex_anthropic = function()
          return require("codecompanion.adapters").extend("vertex-anthropic", {
            formatted_name = "Vertex AI Anthropic",
            env = {
              project_id = "tww-cx-rnd-prod",
            },
          })
        end,
        vertex_maas = function()
          return require("codecompanion.adapters").extend("vertex-maas", {
            formatted_name = "Vertex AI MAAS Global",
            features = {
              show_reasoning = true,
            },
            env = {
              project_id = "tww-cx-rnd-prod",
            },
          })
        end,
        vertex_maas_us_central1 = function()
          return require("codecompanion.adapters").extend("vertex-maas", {
            features = {
              show_reasoning = true,
            },
            formatted_name = "Vertex AI MAAS US-Central1",
            env = {
              project_id = "tww-cx-rnd-prod",
              region = "us-central1",
            },
          })
        end,
        codex = function()
          return require("codecompanion.adapters").extend("codex", {
            opts = {
              profile = "personal",
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
      -- BACKGROUND INTERACTION -------------------------------------------------
      background = {
        adapter = {
          name = "copilot",
          model = "gpt-4.1",
        },
        -- Callbacks within the plugin that you can attach background actions to
        chat = {
          callbacks = {
            -- title generation on ready
            ["on_ready"] = {
              actions = {
                "interactions.background.builtin.chat_make_title",
              },
              enabled = false,
            },
          },
          opts = {
            enabled = true, -- Enable ALL background chat interactions?
          },
        },
      },
      chat = {
        adapter = {
          name = "gemini_code_assist_work",
          model = "gemini-3-flash-preview",
        },
        -- keymaps: for chat buffers, you can bind keys to interact with the current chat and its adapter
        keymaps = {
          copilot_stats = {
            modes = { n = "gS" },
            description = "[Adapter] Usage statistics",
            callback = function(chat)
              if not chat or not chat.adapter then
                return
              end

              local fn = chat.adapter.show_stats or chat.adapter.show_copilot_stats
              if type(fn) == "function" then
                return fn(chat.adapter)
              end

              vim.notify("Stats are not available for this adapter", vim.log.levels.WARN)
            end,
          },
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
          ["terminal"] = {
            callback = "slash_commands.terminal",
            description = "Insert terminal output",
            opts = {
              contains_code = false,
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
            ["agentic"] = {
              description = "Agentic tools that can perform actions autonomously",
              prompt = "I'm giving you access to ${tools} to help you perform file operations",
              tools = {
                "cmd_runner",
                "create_file",
                "delete_file",
                "file_search",
                "grep_search",
                "insert_edit_into_file",
                "read_file",
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
          --- Function to resolve user input from vim.ui.input into the messages
          ---
          --- Processes user input to replace placeholders ($ARGUMENTS, $1, $2, etc.)
          --- or appends a new message if no placeholders are found.
          ---
          --- @param messages table List of message objects {role: string, content: string}
          --- @param input string|nil The raw string retrieved from vim.ui.input
          --- @return nil
          resolve_input = function(messages, input)
            if not input or input == "" then
              return
            end

            -- positional arguments
            local args = {}
            for word in input:gmatch("%S+") do
              table.insert(args, word)
            end

            -- replacements map
            local replacements = {
              ["%$ARGUMENTS"] = input, -- Represents the full plural string
            }
            for i, val in ipairs(args) do
              replacements["%$" .. i] = val
            end

            local replaced_any = false

            -- iterate through existing messages to perform string substitution
            for _, message in ipairs(messages) do
              for pattern, replacement in pairs(replacements) do
                local new_content, n = message.content:gsub(pattern, replacement)
                if n > 0 then
                  message.content = new_content
                  replaced_any = true
                end
              end
            end

            -- if no placeholders were detected, fall back to default behavior
            if not replaced_any then
              original_resolve_input(messages, input)
            end
          end,
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
          vim.fn.expand("~/.codecompanion/prompts"),
          vim.fn.getcwd() .. "/.codecompanion/prompts", -- Can be relative
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
      log_level = "ERROR", -- TRACE|DEBUG|ERROR|INFO
      -- log_level = "TRACE",
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
