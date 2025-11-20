local openai = require("codecompanion.adapters.http.openai")

---@class Gemini.Adapter: CodeCompanion.Adapter
return {
  name = "vertex_regional",
  formatted_name = "Vertex AI Regional",
  roles = {
    llm = "assistant",
    user = "user",
  },
  opts = {
    stream = true,
    tools = true,
  },
  features = {
    text = true,
    tokens = true,
    vision = true,
  },
  -- Availability of models: https://cloud.google.com/vertex-ai/generative-ai/docs/learn/locations
  url = "https://aiplatform.googleapis.com/v1/projects/${project_id}/locations/${region}/endpoints/openapi/chat/completions",
  env = {
    project_id = "YOUR_PROJECT_ID",
    region = "region",
    api_key = nil,
  },
  headers = {
    Authorization = "Bearer ${api_key}",
    ["Content-Type"] = "application/json",
  },
  handlers = {
    --- Use the OpenAI adapter for the bulk of the work
    setup = function(self)
      local cmd = "gcloud auth print-access-token 2>&1"
      local handle = io.popen(cmd, "r")
      if handle then
        local token = handle:read("*a")
        handle:close()
        token = token:gsub("%s+$", "")
        if token and token ~= "" then
          self.env.api_key = token
        end
      end
      return openai.handlers.setup(self)
    end,
    tokens = function(self, data)
      return openai.handlers.tokens(self, data)
    end,
    form_parameters = function(self, params, messages)
      return openai.handlers.form_parameters(self, params, messages)
    end,
    form_tools = function(self, tools)
      return openai.handlers.form_tools(self, tools)
    end,
    form_messages = function(self, messages)
      return openai.handlers.form_messages(self, messages)
    end,
    chat_output = function(self, data, tools)
      return openai.handlers.chat_output(self, data, tools)
    end,
    tools = {
      format_tool_calls = function(self, tools)
        return openai.handlers.tools.format_tool_calls(self, tools)
      end,
      output_response = function(self, tool_call, output)
        return openai.handlers.tools.output_response(self, tool_call, output)
      end,
    },
    inline_output = function(self, data, context)
      return openai.handlers.inline_output(self, data, context)
    end,
    on_exit = function(self, data)
      return openai.handlers.on_exit(self, data)
    end,
  },
  schema = {
    ---@type CodeCompanion.Schema
    model = {
      order = 1,
      mapping = "parameters",
      type = "enum",
      desc = "The model that will complete your prompt. See https://ai.google.dev/gemini-api/docs/models/gemini#model-variations for additional details and options.",
      default = "google/gemini-2.5-flash",
      choices = {
        -- ["vertex_ai/gemini-2.5-pro"] = { opts = { can_reason = true, has_vision = true } },
        ["google/gemini-2.5-pro"] = { opts = { can_reason = true, has_vision = true } },
        ["google/gemini-2.5-flash"] = { opts = { can_reason = true, has_vision = true } },
        ["google/gemini-2.5-flash-lite-preview-06-17"] = { opts = { has_vision = true } },
        ["google/gemini-2.0-flash"] = { opts = { has_vision = true } },
        ["google/gemini-2.0-flash-lite"] = { opts = { has_vision = true } },
        ["google/gemini-1.5-pro"] = { opts = { has_vision = true } },
        ["google/gemini-1.5-flash"] = { opts = { has_vision = true } },
        ["moonshotai/kimi-k2-thinking-maas"] = { opts = { can_reason = true } },
        ["minimaxai/minimax-m2-maas"] = { opts = { can_reason = true } },
        -- ["anthropic/claude-sonnet-4-5"] = { opts = { can_reason = true } },
        ["google/gemini-3-pro-preview"] = { opts = { can_reason = true, has_vision = true } },
        ["google/gemini-2.5-flash-preview-09-2025"] = { opts = { can_reason = true, has_vision = true } },
      },
    },
    ---@type CodeCompanion.Schema
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
    ---@type CodeCompanion.Schema
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
    ---@type CodeCompanion.Schema
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
    ---@type CodeCompanion.Schema
    reasoning_effort = {
      order = 5,
      mapping = "parameters",
      type = "string",
      optional = true,
      condition = function(self)
        local model = self.schema.model.default
        if type(model) == "function" then
          model = model()
        end
        if self.schema.model.choices[model] and self.schema.model.choices[model].opts then
          return self.schema.model.choices[model].opts.can_reason
        end
      end,
      default = "medium",
      desc = "Constrains effort on reasoning for reasoning models. Reducing reasoning effort can result in faster responses and fewer tokens used on reasoning in a response.",
      choices = {
        "high",
        "medium",
        "low",
        "none",
      },
    },
  },
}
