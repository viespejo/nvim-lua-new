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
        enabled = true,
        opts = {},
      },
      mode = {
        enabled = false,
        opts = {},
      },
      custom_modes = {
        enabled = true,
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
        enabled = true,
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
        anthropic = function()
          return require("codecompanion.adapters").extend("anthropic", {
            schema = {
              extended_thinking = {
                default = true,
              },
            },
          })
        end,
        copilot = function()
          return require("codecompanion.adapters").extend("copilot", {
            schema = {
              model = {
                -- default = "claude-3.7-sonnet",
                -- default = "gemini-2.5-pro",
                -- default = "claude-sonnet-4",
                -- default = "gpt-4.1",
                default = "gpt-5-mini",
              },
              -- gpt-5-mini to reasoning_effort "minimal"
              reasoning_effort = {
                mapping = "parameters",
                type = "string",
                optional = true,
                condition = function(self)
                  local model = self.model.name:lower()
                  if type(model) == "function" then
                    model = model()
                  end
                  if model == "gpt-5-mini" then
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
        vertex = function()
          return require("codecompanion.adapters").extend("vertex", {
            env = {
              project_id = "tww-cx-rnd-prod",
            },
          })
        end,
        vertex_regional = function()
          return require("codecompanion.adapters.http").extend("vertex_regional", {
            env = {
              project_id = "tww-cx-rnd-prod",
              region = "us-central1",
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
        gemini_cli = function()
          return require("codecompanion.adapters").extend("gemini_cli", {
            commands = {
              flash = {
                "gemini",
                "--experimental-acp",
                "-m",
                "gemini-2.5-flash",
              },
              pro = {
                "gemini",
                "--experimental-acp",
                "-m",
                "gemini-2.5-pro",
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
    strategies = {
      chat = {
        -- adapter = {
        -- 	name = "copilot",
        -- 	-- model = "claude-sonnet-4",
        -- 	model = "gpt-4.1",
        -- },
        adapter = "copilot",
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
      },
      inline = {
        -- adapter = {
        -- 	name = "copilot",
        -- 	model = "gpt-4.1",
        -- },
        adapter = "copilot",
      },
    },
    prompt_library = {
      ["Explain"] = {
        opts = {
          auto_submit = false,
        },
      },
      ["Fix code"] = {
        opts = {
          auto_submit = false,
        },
      },
      ["Unit Tests"] = {
        opts = {
          auto_submit = false,
        },
      },
      ["Generate a Commit Message"] = {
        opts = {
          auto_submit = false,
        },
      },
      ["Generate a Commit Message (no staged)"] = {
        strategy = "chat",
        description = "Generate a commit message",
        opts = {
          index = 10,
          is_default = true,
          is_slash_cmd = true,
          short_name = "commit_no_staged",
          auto_submit = false,
        },
        prompts = {
          {
            role = "user",
            content = function()
              return fmt(
                [[You are an expert at following the Conventional Commit specification. Given the git diff listed below, please generate a commit message for me:

```diff
%s
```
]],
                vim.fn.system("git diff")
              )
            end,
            opts = {
              contains_code = true,
            },
          },
        },
      },
      ["Maths tutor"] = {
        strategy = "chat",
        description = "Chat with your personal maths tutor",
        opts = {
          index = 12,
          ignore_system_prompt = true,
          intro_message = "Welcome to your lesson! How may I help you today? ",
        },
        prompts = {
          {
            role = "system",
            content = [[You are a helpful maths tutor.
You explain concepts, solve problems, and provide step-by-step solutions for maths.
The user has an MPhys in Physics, is knowledgeable in maths but out of practice, and is an experienced programmer.
Relate maths concepts to programming where possible.

When responding, use this structure:
1. Brief explanation of the topic
2. Definition
3. Simple example and a more complex example
4. Programming analogy or Python example
5. Summary of the topic
6. Question to check user understanding

You must:
- Use only H3 headings and above for section separation
- Show your work and explain each step clearly
- Relate maths concepts to programming terms where applicable
- Use Python for coding examples (triple backticks with 'python')
- Make answers concise for easy transfer to Notion and Anki
- End with a flashcard-ready summary or question

If the user requests only part of the structure, respond accordingly.]],
          },
        },
      },
      ["Chain-of-Thought"] = {
        strategy = "workflow",
        description = "Use a CoT workflow to plan and write code",
        opts = {
          index = 12,
        },
        prompts = {
          {
            {
              role = "user",
              content = [[DO NOT WRITE ANY CODE YET.

Your task is to act as an expert software architect and create a comprehensive implementation plan.

First, think step-by-step. Then, provide a detailed pseudocode plan that outlines the solution.

Your plan should include:
1.  A high-level summary of the proposed approach.
2.  A breakdown of the required logic into sequential steps.
3.  Identification of any new functions, classes, or components that should be created.
4.  Consideration of how the changes will interact with existing code.
5.  A list of potential edge cases and error conditions to handle.

<!-- Be sure to share any relevant files -->
<!-- Your task here -->]],
              opts = {
                auto_submit = false,
              },
            },
          },
          {
            {
              role = "user",
              content = [[Now, act as a senior technical lead reviewing the previous plan. Your goal is to refine it into a final, highly-detailed specification that another AI can implement flawlessly.

Critically evaluate the plan by answering the following questions:
1.  What are the strengths and weaknesses of the proposed approach?
2.  Are there any alternative approaches? If so, what are their trade-offs?
3.  What potential risks, edge cases, or dependencies did the initial plan miss?
4.  How can the pseudocode be made more specific and closer to the target language's syntax and conventions?

After your analysis, provide a final, revised pseudocode plan. This new plan should incorporate your improvements, be extremely detailed, and leave no room for ambiguity.]],
              opts = {
                -- adapter = {
                --   name = "copilot",
                --   model = "claude-sonnet-4",
                -- },
                auto_submit = true,
              },
            },
          },
          {
            {
              role = "user",
              content = [[Your task is to write the code based on the final implementation plan that we discussed. Adhere strictly to the plan and do not introduce any new logic.

**Instructions:**
1.  Implement the plan.
2.  Generate only the code. Do not include explanations or conversational text.
3.  Use Markdown code blocks for the code (use 4 backticks instead of 3)
4.  If you are modifying an existing file, include a comment with its path (e.g., `// filepath: src/utils/helpers.js`).
5.  Use comments like `// ...existing code...` to indicate where the new code should be placed within existing files.

**IMPORTANT:**
- Follow the plan exactly.
- Ensure comments are correct for the programming language.]],
              opts = {
                -- adapter = {
                --   name = "copilot",
                --   model = "gpt-4.1",
                -- },
                auto_submit = true,
              },
            },
          },
        },
      },
    },
    -- MEMORY OPTIONS -----------------------------------------------------------
    memory = {
      default = {
        files = {
          ".clinerules",
          ".cursorrules",
          ".goosehints",
          ".rules",
          ".windsurfrules",
          ".github/copilot-instructions.md",
          "AGENT.md",
          "AGENTS.md",
          { path = "CLAUDE.md", parser = "claude" },
          { path = "CLAUDE.local.md", parser = "claude" },
          { path = "~/.claude/CLAUDE.md", parser = "claude" },
        },
      },
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
    },
    -- GENERAL OPTIONS ----------------------------------------------------------
    opts = {
      log_level = "DEBUG", -- TRACE|DEBUG|ERROR|INFO
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
