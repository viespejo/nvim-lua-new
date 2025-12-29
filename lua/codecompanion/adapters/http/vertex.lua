local adapters = require("codecompanion.adapters")
local gemini = require("codecompanion.adapters.http.gemini")

local M = adapters.extend(gemini, {
  name = "vertex",
  formatted_name = "Vertex AI",
  -- Availability of models: https://cloud.google.com/vertex-ai/generative-ai/docs/learn/locations
  url = "https://aiplatform.googleapis.com/v1/projects/${project_id}/locations/global/endpoints/openapi/chat/completions",
  env = {
    project_id = "YOUR_PROJECT_ID",
    api_key = nil,
  },
  handlers = {
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
      return gemini.handlers.setup(self)
    end,
  },
})

M.schema.model.default = "google/gemini-3-flash-preview"
M.schema.model.choices = {
  ["google/gemini-3-pro-preview"] = {
    formatted_name = "Gemini 3 Pro",
    opts = { can_reason = true, has_vision = true },
  },
  ["google/gemini-3-flash-preview"] = {
    formatted_name = "Gemini 3 Flash",
    opts = { can_reason = true, has_vision = true },
  },
  ["google/gemini-2.5-pro"] = {
    formatted_name = "Gemini 2.5 Pro",
    opts = { can_reason = true, has_vision = true },
  },
  ["google/gemini-2.5-flash"] = {
    formatted_name = "Gemini 2.5 Flash",
    opts = { can_reason = true, has_vision = true },
  },
  ["google/gemini-2.5-flash-preview-05-20"] = {
    formatted_name = "Gemini 2.5 Flash Preview",
    opts = { can_reason = true, has_vision = true },
  },
  ["google/gemini-2.0-flash"] = { formatted_name = "Gemini 2.0 Flash", opts = { has_vision = true } },
  ["google/gemini-2.0-flash-lite"] = { formatted_name = "Gemini 2.0 Flash Lite", opts = { has_vision = true } },
  ["google/gemini-1.5-pro"] = { formatted_name = "Gemini 1.5 Pro", opts = { has_vision = true } },
  ["google/gemini-1.5-flash"] = { formatted_name = "Gemini 1.5 Flash", opts = { has_vision = true } },
  ["moonshotai/kimi-k2-thinking-maas"] = {
    formatted_name = "Kimi K2 Thinking",
    opts = { can_reason = true, has_vision = true },
  },
  ["minimaxai/minimax-m2-maas"] = {
    formatted_name = "Minimax M2",
    opts = { can_reason = true, has_vision = true },
  },
  -- ["anthropic/claude-sonnet-4-5"] = { opts = { can_reason = true } },
}

return M
