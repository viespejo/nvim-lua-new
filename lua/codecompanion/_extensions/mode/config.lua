local M = {}

local default_config = {
	mode_agent_keymap = "gA",
	rules_files = {
		"AGENTS.md",
	},
}

local config = vim.deepcopy(default_config)

function M.setup(user_config)
	config = vim.tbl_deep_extend("force", default_config, user_config)
end

function M.get()
	return config
end

return M
