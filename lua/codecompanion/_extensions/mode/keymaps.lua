local M = {}

local extension_config = require("codecompanion._extensions.mode.config")
local utils_callbacks = require("codecompanion._extensions.mode.utils.callbacks")

function M.setup()
	local config = extension_config.get()
	local keymaps = {
		mode_agent = {
			modes = { n = config.mode_agent_keymap },
			callback = utils_callbacks.rules_to_system_prompt(config.rules_files),
			description = "Add rules files as system prompt to chat",
		},
	}

	return keymaps
end

return M
