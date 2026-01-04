## Gemini Code Assist Adapter for CodeCompanion

This adapter connects to Google's Gemini Code Assist API (the internal API used by Gemini CLI and VS Code). It features an automated OAuth2 flow, automated project provisioning (Zero Config), and support for multiple Google accounts via profiles.

## File Structure

Create a directory named `gemini-code-assist` inside your CodeCompanion adapters path:

```text
lua/codecompanion/adapters/http/gemini-code-assist/
├── init.lua       (Adapter definition)
├── auth.lua       (OAuth2 manager)
└── constants.lua  (Shared configuration)
```

## Installation

1. Copy the **Auth Module** code into `lua/codecompanion/adapters/http/gemini-code-assist/auth.lua`.
2. Copy the **Adapter Definition** code into `lua/codecompanion/adapters/http/gemini-code-assist/init.lua`.

## Configuration

### Environment Variables
The adapter can automatically resolve configuration from your system environment:
- `GEMINI_CODE_ASSIST_PROJECT_ID`: Your Google Cloud Project ID.

### Basic Setup (Zero Config)
If you don't provide a `project_id`, the adapter will automatically attempt to provision a "Free Tier" managed project for your Google account.

```lua
require("codecompanion").setup({
  adapters = {
    gemini_code_assist = function()
      return require("codecompanion.adapters").extend("gemini-code-assist")
    end,
  },
  interactions = {
    chat = { adapter = "gemini_code_assist" },
  },
})
```

### Multi-Account Support (Profiles)
You can use multiple Google accounts by defining different profiles. Each profile maintains its own separate token file.

```lua
require("codecompanion").setup({
  adapters = {
    gemini_personal = function()
      return require("codecompanion.adapters").extend("gemini-code-assist", {
        opts = { profile = "personal" }
      })
    end,
    gemini_work = function()
      return require("codecompanion.adapters").extend("gemini-code-assist", {
        opts = { profile = "work" },
        env = {
          project_id = "my-corporate-project-id", -- Optional: force a specific project
        }
      })
    end,
  },
})
```

## Authentication Flow

1.  **Automatic**: When you start a chat, the adapter checks for a valid token. If missing, it notifies you and opens your browser.
2.  **Loopback Server**: A temporary local server captures the authorization code automatically.
3.  **Manual Trigger**: You can re-authenticate or log in to a specific profile at any time using:
    *   `:CodeCompanionGeminiAuth` (default profile)
    *   `:CodeCompanionGeminiAuth work` (specific profile)

## Key Features

- **Zero Config**: Automatically provisions a free managed project if `project_id` is omitted.
- **Multi-Profile**: Support for multiple Google accounts via the `opts.profile` setting.
- **Reasoning/Thinking**: Supports Gemini 3 "Thinking" models with `reasoning_effort` and `include_thoughts`.
- **Vision**: Automatic detection of image support based on the selected model.
- **Tools**: Fully compatible with CodeCompanion's Agents and Tools ecosystem.

## Troubleshooting

- **Project Errors**: If automated provisioning fails, ensure the "Gemini for Google Cloud API" is enabled in your [GCP Console](https://console.cloud.google.com/apis/library/cloudaicompanion.googleapis.com).
- **Port Conflicts**: The adapter uses a random free port for the authentication callback. If you are behind a strict firewall, ensure local loopback connections are allowed.
- **Logs**: Use `:CodeCompanionLog` to view detailed request/response data if authentication fails.
- **Token Location**: Tokens are stored in `stdpath("data")` as `gemini_code_assist_token_[profile].json`.
