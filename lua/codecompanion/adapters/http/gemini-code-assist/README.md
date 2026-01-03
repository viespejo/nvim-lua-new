## Gemini Code Assist Adapter for CodeCompanion

This adapter allows you to connect to Google's Gemini Code Assist API using the same infrastructure as the Gemini CLI and VS Code extensions. It includes an automated OAuth2 authentication flow and supports advanced features like Reasoning (Thinking) and Tool Use.

## File Structure

Create a folder named `gemini-code-assist` inside your CodeCompanion adapters directory:

```text
lua/codecompanion/adapters/http/gemini-code-assist/
├── init.lua   (The adapter definition)
└── auth.lua   (The OAuth2 manager)
```

## Installation

1. Copy the **Auth Module** code into `lua/codecompanion/adapters/http/gemini-code-assist/auth.lua`.
2. Copy the **Adapter Definition** code into `lua/codecompanion/adapters/http/gemini-code-assist/init.lua`.

## Configuration

Add the adapter to your `codecompanion.lua` configuration file. You must provide your Google Cloud **Project ID**:

```lua
require("codecompanion").setup({
  adapters = {
    gemini_code_assist = function()
      return require("codecompanion.adapters").extend("gemini-code-assist", {
        env = {
          project_id = "your-gcp-project-id", -- Replace with your actual GCP project ID
        },
      })
    end,
  },
  interactions = {
    chat = { adapter = "gemini_code_assist" },
    inline = { adapter = "gemini_code_assist" },
  },
})
```

## Authentication Flow

The adapter handles authentication automatically using a local loopback server:

1. **Automatic Activation**: The first time you open a CodeCompanion chat or use the adapter, it will detect that no token is present.
2. **Browser Prompt**: A notification will appear, and your default browser will open a Google login page.
3. **Authorization**: Log in with your Google account and grant the necessary permissions.
4. **Token Storage**: Once authorized, the browser will show "Authentication Successful". The tokens are securely saved to `~/.local/share/nvim/gemini_code_assist_token.json` (or equivalent on your OS - see your `stdpath("data")`).
5. **Manual Trigger**: You can re-authenticate at any time by running the command:
   `:CodeCompanionGeminiAuth`

## Key Features

- **Reasoning/Thinking**: Supports Gemini 3 models with `reasoning_effort` (high, medium, low) and `include_thoughts` options.
- **Vision**: Automatically detects if the selected model supports image inputs.
- **Tools**: Fully compatible with CodeCompanion's tool ecosystem (Agents).
- **Persistent Session**: The refresh token lasts for a long duration, so you won't need to log in frequently.

## Troubleshooting

- **Project ID**: Ensure your GCP Project ID has the "Gemini for Google Cloud API" enabled.
- **Port Conflicts**: The adapter uses a random free port for the authentication callback. If you are behind a strict firewall, ensure local loopback connections are allowed.
- **Logs**: You can check the logs using `:CodeCompanionLog` if the authentication fails to exchange the code.
