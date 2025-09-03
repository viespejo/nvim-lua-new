local M = {}

function M.rules_to_system_prompt(rules_files)
	local function callback(chat)
		local start_path = vim.fs.dirname(vim.api.nvim_buf_get_name(chat.bufnr))
		local found_files = {}

		local function add_rules_to_system_prompt(dir)
			for _, rule in ipairs(rules_files) do
				local path = vim.fs.joinpath(dir, rule)
				if vim.uv.fs_stat(path) and not vim.list_contains(found_files, path) then
					table.insert(found_files, path)
				end
			end

			-- loop through all found_files in the directory and concat them
			local contents = {}
			if #found_files then
				for _, file in ipairs(found_files) do
					local content = table.concat(vim.fn.readfile(file), "\n")
					-- add to contents
					table.insert(contents, content)
				end
			end

			local systems_prompt = table.concat(contents, "\n\n")
			if systems_prompt == "" then
				vim.notify(
					"No context files found or empties in " .. dir,
					vim.log.levels.INFO,
					{ title = "CodeCompanion" }
				)
				return
			end

			-- remove existing system prompt con "from_config" tag
			chat:remove_tagged_message("from_config")

			-- add to system prompt
			chat:add_system_prompt(systems_prompt, { visible = false, tag = "from_config", index = 1 })

			vim.notify(
				"Added " .. #found_files .. " rules files from " .. dir,
				vim.log.levels.INFO,
				{ title = "CodeCompanion" }
			)
		end

		add_rules_to_system_prompt(start_path)
		-- for dir in vim.fs.parents(start_path) do
		-- 	try_add_rules_to_system_prompt(dir)
		-- end
	end

	return callback
end

return M
