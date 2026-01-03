local curl = require("plenary.curl")
local adapter_utils = require("codecompanion.utils.adapters")
local log = require("codecompanion.utils.log")
local auth = require("codecompanion.adapters.http.gemini-code-assist.auth")
local config = require("codecompanion.config")

-- =============================================================================
-- CONFIG & AUTH
-- =============================================================================
local CONFIG = {
  CLIENT_ID = vim.env.GEMINI_CLIENT_ID or "681255809395-oo8ft2oprdrnp9e3aqf6av3hmdib135j.apps.googleusercontent.com",
  CLIENT_SECRET = vim.env.GEMINI_CLIENT_SECRET or "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",
  TOKEN_URL = "https://oauth2.googleapis.com/token",
  API_BASE_URL = "https://cloudcode-pa.googleapis.com/v1internal",
}

-- create command to force login if needed
vim.api.nvim_create_user_command("CodeCompanionGeminiAuth", function()
  auth.authenticate()
end, {})

local token_cache = { access_token = nil, expires_at = 0 }

---Get a fresh access token
---@return string|nil
local function get_fresh_token()
  -- 1. Check memory cache
  if token_cache.access_token and os.time() < (token_cache.expires_at - 120) then
    return token_cache.access_token
  end

  -- 2. Check disk (via Auth module)
  local refresh_token = auth.load_token()

  if not refresh_token then
    -- we do NOT trigger auth here
    -- Auth is triggered in the 'resolve' handler.
    vim.notify("Gemini: Authentication required. Please run :CodeCompanionGeminiAuth", vim.log.levels.WARN)
    return nil
  end

  log:trace("Gemini Code Assist: Refreshing access token...")
  local ok, response = pcall(curl.post, CONFIG.TOKEN_URL, {
    insecure = config.adapters.http.opts.allow_insecure,
    proxy = config.adapters.http.opts.proxy,
    body = {
      client_id = CONFIG.CLIENT_ID,
      client_secret = CONFIG.CLIENT_SECRET,
      refresh_token = refresh_token,
      grant_type = "refresh_token",
    },
    timeout = 10000,
  })

  if not ok then
    log:error("Gemini Code Assist: Network error during token refresh: %s", response)
    return nil
  end

  if response.status == 200 then
    local decode_ok, data = pcall(vim.json.decode, response.body)
    if decode_ok and data and data.access_token then
      token_cache.access_token = data.access_token
      token_cache.expires_at = os.time() + (data.expires_in or 3599)
      log:trace("Gemini Code Assist: Token refreshed successfully")
      return data.access_token
    else
      log:error("Gemini Code Assist: Failed to decode token response: %s", response.body)
    end
  else
    log:error("Gemini Code Assist: Token refresh failed (Status %s): %s", response.status, response.body)
  end

  return nil
end

-- =============================================================================
-- HELPERS
-- =============================================================================

---Provides the schemas of the tools that are available to the LLM to call
---@param tools table<string, table>
---@return table|nil
local function transform_tools(tools)
  if not tools or vim.tbl_isempty(tools) then
    return nil
  end

  local declarations = {}

  for _, group in pairs(tools) do
    for _, tool in pairs(group) do
      local name = tool.name
      local description = tool.description
      local parameters = tool.parameters

      if tool["function"] then
        name = tool["function"].name
        description = tool["function"].description
        parameters = tool["function"].parameters
      end

      if parameters then
        -- Clean up parameters for Gemini strictness
        local allowed = {
          type = true,
          properties = true,
          required = true,
        }
        for key in pairs(parameters) do
          if not allowed[key] then
            parameters[key] = nil
          end
        end

        if parameters.properties then
          local allowed_props = {
            type = true,
            description = true,
            enum = true,
          }
          for _, param in pairs(parameters.properties) do
            for key in pairs(param) do
              if not allowed_props[key] then
                param[key] = nil
              end
            end
            -- flatten array types
            if param.type and type(param.type) == "table" and #param.type > 0 then
              param.type = param.type[1]
            end
          end
        end
      end

      table.insert(declarations, {
        name = name,
        description = description,
        parameters = parameters,
      })
    end
  end

  if #declarations == 0 then
    return nil
  end

  return { { functionDeclarations = declarations } }
end

local function transform_messages(messages, opts)
  -- Separate out system messages so they can be sent as instructions
  local instruction = vim
    .iter(messages)
    :filter(function(m)
      return m.role == "system"
    end)
    :map(function(m)
      return m.content
    end)
    :totable()

  local system_instruction = #instruction > 0 and { parts = { { text = table.concat(instruction, "\n") } } } or nil

  -- Find the cycle of the last function call for reasoning matching
  local last_func_cycle = nil
  for i = #messages, 1, -1 do
    local m = messages[i]
    if m.tools and m.tools.calls then
      last_func_cycle = m._meta and m._meta.cycle or nil
      break
    end
  end

  local contents = {}
  local i = 1
  while i <= #messages do
    local m = messages[i]
    if m.role ~= "system" then
      local role = (m.role == "user") and "user" or "model"
      local parts = {}

      if m.role == "function" then
        role = "user" -- Function results are sent as 'user' in Gemini

        -- group all consecutive function messages into a single parts block
        -- because Gemini expects function responses to be in the same message
        while i <= #messages and messages[i].role == "function" do
          local current_f = messages[i]
          local response_content = current_f.content
          local ok, json_content = pcall(vim.json.decode, current_f.content)

          if ok and type(json_content) == "table" then
            response_content = json_content
          else
            response_content = { content = current_f.content }
          end

          table.insert(parts, {
            functionResponse = {
              name = current_f.tools and current_f.tools.name or "unknown_function",
              response = response_content,
            },
          })
          i = i + 1
        end
        i = i - 1 -- Adjust for the outer loop increment
      elseif m.tools and m.tools.calls then
        local tool_calls = vim
          .iter(m.tools.calls)
          :map(function(tool_call)
            return {
              functionCall = {
                name = tool_call["function"].name,
                args = vim.json.decode(tool_call["function"].arguments),
              },
              thoughtSignature = (m._meta and last_func_cycle == m._meta.cycle) and tool_call.thought_signature or nil,
            }
          end)
          :totable()

        for _, tool_call in ipairs(tool_calls) do
          table.insert(parts, tool_call)
        end
      elseif m._meta and m._meta.tag == "image" and (m.context and m.context.mimetype) then
        -- image message
        if opts and opts.vision then
          table.insert(parts, {
            {
              inline_data = {
                data = m.content,
                mime_type = m.context.mimetype,
              },
            },
          })
        else
          log:warn("Vision is not enabled for this adapter, skipping image message.")
        end
      elseif m.content and m.content ~= "" then
        table.insert(parts, { text = m.content })
      end

      if #parts > 0 then
        table.insert(contents, { role = role, parts = parts })
      end
    end
    i = i + 1
  end

  return contents, system_instruction
end

local function resolve_model_opts(adapter)
  local model = adapter.schema.model.default
  local choices = adapter.schema.model.choices
  if type(model) == "function" then
    model = model(adapter)
  end
  if type(choices) == "function" then
    choices = choices(adapter)
  end

  return choices and choices[model] or { opts = {} }
end

-- =============================================================================
-- ADAPTER DEFINITION
-- =============================================================================
return {
  name = "gemini_code_assist",
  formatted_name = "Gemini Code Assist",
  roles = {
    llm = "model",
    user = "user",
    tool = "function",
  },
  opts = {
    tools = true,
    stream = true,
    vision = true,
  },
  features = {
    text = true,
    tokens = true,
  },
  url = CONFIG.API_BASE_URL,
  env = {
    project_id = "YOUR_PROJECT_ID", -- replace in config
    access_token = "", -- Not used directly - placeholder
  },
  headers = {
    ["Authorization"] = "Bearer ${access_token}",
    ["Content-Type"] = "application/json",
    ["X-Goog-Api-Client"] = "gl-node/22.17.0",
    ["Client-Metadata"] = "ideType=IDE_UNSPECIFIED,platform=PLATFORM_UNSPECIFIED,pluginType=GEMINI",
  },

  handlers = {
    resolve = function(self)
      local refresh_token = auth.load_token()
      if not refresh_token then
        vim.schedule(function()
          auth.authenticate()
        end)
      end
    end,
    lifecycle = {
      setup = function(self)
        if not self.env.project_id or self.env.project_id == "YOUR_PROJECT_ID" then
          log:error("Gemini Code Assist: project_id is missing in env")
          return false
        end

        -- get fresh token
        self.env.access_token = get_fresh_token()
        if not self.env.access_token then
          return false
        end

        -- set endpoint based on streaming or not
        if self.opts and self.opts.stream then
          self.url = CONFIG.API_BASE_URL .. ":streamGenerateContent?alt=sse"
          self.headers["Accept"] = "text/event-stream"
        else
          self.url = CONFIG.API_BASE_URL .. ":generateContent"
        end

        local model_opts = resolve_model_opts(self)
        self.opts.vision = model_opts.opts and model_opts.opts.has_vision or false

        return true
      end,
    },
    request = {
      -- IMPORTANT: We return nil in these builders so that they do NOT
      -- inject anything into the root of the JSON and avoid conflicts.
      build_parameters = function()
        return nil
      end,
      build_messages = function()
        return nil
      end,
      build_tools = function()
        return nil
      end,

      -- BUILD BODY: master assembler because Gemini needs a very specific format
      build_body = function(self, payload)
        local model = self.schema.model.default
        local model_opts = resolve_model_opts(self)

        -- transform messages and tools
        local contents, system_instruction = transform_messages(payload.messages, self.opts)
        local tools_gemini = transform_tools(payload.tools)

        local generation_config = {}
        local params = adapter_utils.set_env_vars(self, self.parameters) or {}

        if params.max_tokens then
          generation_config.maxOutputTokens = params.max_tokens
        end
        if params.temperature then
          generation_config.temperature = params.temperature
        end
        if params.top_p then
          generation_config.topP = params.top_p
        end

        -- reasoning configuration
        -- gemini 3 thinkingLevel
        -- gemini 2.5 use thinkingBudget
        if model_opts.opts and model_opts.opts.can_reason then
          generation_config.thinkingConfig = { includeThoughts = params.include_thoughts }
          if params.reasoning_effort then
            if model:find("gemini%-3") then
              generation_config.thinkingConfig.thinkingLevel = params.reasoning_effort ~= "none"
                  and params.reasoning_effort
                or "minimal"
            else
              -- Legacy/Pro models using budget
              local is_pro = model:find("pro") ~= nil
              local budget_map = {
                none = is_pro and 1024 or 0,
                minimal = 1024,
                low = 1024,
                medium = 8192,
                high = 24576,
              }
              generation_config.thinkingConfig.thinkingBudget = budget_map[params.reasoning_effort]
            end
          end
        end

        if vim.tbl_isempty(generation_config) then
          generation_config = nil
        end

        return {
          project = self.env.project_id,
          model = model,
          request = {
            contents = contents,
            systemInstruction = system_instruction,
            tools = tools_gemini,
            generationConfig = generation_config,
          },
        }
      end,
    },
    response = {
      parse_tokens = function(self, data)
        if not data or data == "" then
          return nil
        end

        local data_mod = adapter_utils.clean_streamed_data(data)
        local ok, json = pcall(vim.json.decode, data_mod, { luanil = { object = true } })

        if ok and json.response and json.response.usageMetadata then
          return json.response.usageMetadata.totalTokenCount
        end
      end,
      parse_chat = function(self, data, tools)
        if not data or data == "" then
          return nil
        end

        local data_mod = adapter_utils.clean_streamed_data(data)
        local ok, json = pcall(vim.json.decode, data_mod, { luanil = { object = true } })

        if not ok or not json.response or not json.response.candidates or #json.response.candidates == 0 then
          return nil
        end

        local response = json.response
        local candidate = response.candidates[1]
        local content_obj = candidate.content

        local output_text = ""
        local output_reasoning = ""

        if content_obj and content_obj.parts then
          for _, part in ipairs(content_obj.parts) do
            if part.thought and part.text then
              output_reasoning = output_reasoning .. part.text
            end

            if part.text and not part.thought then
              output_text = output_text .. part.text
            end

            if part.functionCall then
              -- [API will wait a functionResponse for each functionCall in the same message]
              -- see interactions/chat/init.lua Chat:add_tool_output where tool output are merged by call_id
              -- we need to avoid call_id merging in order to be able to handle multiple function calls in the same message
              -- how? generating a unique call_id here for each function call
              local call_id = string.format("call_%s_%s", response.responseId or "gen", vim.uv.hrtime())

              table.insert(tools, {
                id = call_id,
                type = "function",
                ["function"] = {
                  name = part.functionCall.name,
                  arguments = vim.json.encode(part.functionCall.args) or "",
                },
                thought_signature = part.thoughtSignature or nil,
              })
            end
          end
        end

        if output_text == "" and output_reasoning == "" and (not tools or #tools == 0) then
          return nil
        end

        return {
          status = "success",
          output = {
            role = "assistant",
            content = output_text ~= "" and output_text or nil,
            reasoning = output_reasoning ~= "" and { content = output_reasoning } or nil,
          },
        }
      end,
    },
    tools = {
      format_calls = function(self, tools)
        return tools
      end,
      format_response = function(self, tool_call, output)
        return {
          role = self.roles.tool or "tool",
          tools = {
            call_id = tool_call.id,
            name = tool_call["function"].name,
          },
          content = output,
          opts = { visible = false },
        }
      end,
    },
  },

  schema = {
    model = {
      order = 1,
      mapping = "parameters",
      type = "enum",
      desc = "The model that will complete your prompt. See https://ai.google.dev/gemini-api/docs/models/gemini#model-variations for additional details and options.",
      default = "gemini-3-flash-preview",
      choices = {
        ["gemini-3-pro-preview"] = {
          formatted_name = "Gemini 3 Pro",
          opts = { can_reason = true, has_vision = true },
        },
        ["gemini-3-flash-preview"] = {
          formatted_name = "Gemini 3 Flash",
          opts = { can_reason = true, has_vision = true },
        },
        ["gemini-2.5-pro"] = {
          formatted_name = "Gemini 2.5 Pro",
          opts = { can_reason = true, has_vision = true },
        },
        ["gemini-2.5-flash"] = {
          formatted_name = "Gemini 2.5 Flash",
          opts = { can_reason = true, has_vision = true },
        },
      },
    },
    max_tokens = {
      order = 2,
      mapping = "parameters",
      type = "integer",
      optional = true,
      default = nil,
      desc = "The maximum number of tokens to include in a response candidate. Note: The default value varies by model",
      validate = function(n)
        return n > 0, "Must be greater than 0"
      end,
    },
    temperature = {
      order = 3,
      mapping = "parameters",
      type = "number",
      optional = true,
      default = nil,
      desc = "Controls the randomness of the output.",
      validate = function(n)
        return n >= 0 and n <= 2, "Must be between 0 and 2"
      end,
    },
    top_p = {
      order = 4,
      mapping = "parameters",
      type = "integer",
      optional = true,
      default = nil,
      desc = "The maximum cumulative probability of tokens to consider when sampling. The model uses combined Top-k and Top-p (nucleus) sampling. Tokens are sorted based on their assigned probabilities so that only the most likely tokens are considered. Top-k sampling directly limits the maximum number of tokens to consider, while Nucleus sampling limits the number of tokens based on the cumulative probability.",
      validate = function(n)
        return n > 0, "Must be greater than 0"
      end,
    },
    reasoning_effort = {
      order = 5,
      mapping = "parameters",
      type = "string",
      optional = true,
      enabled = function(self)
        local model_opts = resolve_model_opts(self)
        return model_opts.opts and model_opts.opts.can_reason
      end,
      default = "high",
      desc = "Constrains effort on reasoning for reasoning models. Reducing reasoning effort can result in faster responses and fewer tokens used on reasoning in a response. See https://docs.cloud.google.com/vertex-ai/generative-ai/docs/thinking for details and options.",
      choices = {
        "high",
        "medium",
        "low",
        "minimal",
        "none",
      },
    },
    include_thoughts = {
      order = 6,
      mapping = "parameters",
      type = "boolean",
      optional = true,
      enabled = function(self)
        local model_opts = resolve_model_opts(self)
        return model_opts.opts and model_opts.opts.can_reason
      end,
      default = true,
      desc = "Whether to include the model's thoughts in the response.",
    },
  },
}
