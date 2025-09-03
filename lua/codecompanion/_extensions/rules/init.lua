--=============================================================================
--  CodeCompanion-Rules  –  manage rule files via chat.refs only
--=============================================================================

---@class CodeCompanionChatMessage
---@field content? string
---@field opts? table
---@field opts.reference? string
---@field role? string
---@field id? any
---@field cycle? any

---@class CodeCompanionRulesConfig
---@field rules_filenames string[]
---@field debug boolean
---@field enabled boolean
---@field extract_file_paths_from_chat_message? fun(message:CodeCompanionChatMessage):string[]|nil

local M = {} -- public module table

--──────────────────────────────────────────────────────────────────────────────
--  Configuration
--──────────────────────────────────────────────────────────────────────────────
---@type CodeCompanionRulesConfig
M.config = {
	rules_filenames = {
		".rules",
		".goosehints",
		".cursorrules",
		".windsurfrules",
		".clinerules",
		".github/copilot-instructions.md",
		"AGENT.md",
		"AGENTS.md",
		"CLAUDE.md",
		".codecompanionrules",
	},
	debug = false,
	enabled = true,
	extract_file_paths_from_chat_message = nil,
}

--──────────────────────────────────────────────────────────────────────────────
--  Per-buffer caches
--──────────────────────────────────────────────────────────────────────────────
local enabled = {} ---@type table<number,boolean>
local fingerprint = {} ---@type table<number,string>

--──────────────────────────────────────────────────────────────────────────────
--  Small helpers
--──────────────────────────────────────────────────────────────────────────────
local function log(msg)
	if M.config.debug then
		print("[Rules] " .. msg)
	end
end

local function notify(msg, level)
	vim.schedule(function()
		vim.notify("[CodeCompanionRules] " .. msg, level or vim.log.levels.INFO, { title = "CodeCompanionRules" })
	end)
end

local function normalize(p)
	return vim.fn.fnamemodify(p, ":p"):gsub("/$", "")
end
local function clean(p)
	return p:gsub("^[`\"'%s]+", ""):gsub("[`\"'%s]+$", "")
end

local function hash(list)
	if #list == 0 then
		return ""
	end
	table.sort(list)
	return table.concat(list, "|")
end

-- test whether a Ref object is a “file” ref
local function is_file_ref(ref)
	return (type(ref.id) == "string" and ref.id:match("^<file>"))
		or (type(ref.source) == "string" and ref.source:match("%.file$"))
end

local function id_to_path(id)
	return id:match("^<file>(.*)</file>$") or id
end

------------------------------------------------------------------------
-- Find the *first* existing file from a list of names in a directory
------------------------------------------------------------------------
local function find_first_file(dir, names)
	for _, name in ipairs(names) do
		local path = dir .. "/" .. name
		if vim.fn.filereadable(path) == 1 then
			return path
		end
	end
end

--──────────────────────────────────────────────────────────────────────────────
--  Extract paths mentioned in chat
--──────────────────────────────────────────────────────────────────────────────
local function collect_paths(bufnr)
	if not M.config.enabled then
		return {}
	end
	local chat = require("codecompanion.strategies.chat").buf_get_chat(bufnr)
	if not chat then
		return {}
	end

	local proj = normalize(vim.fn.getcwd())
	local out, seen = {}, {}

	local function is_rule_file(p)
		local name = vim.fn.fnamemodify(p, ":t")
		return vim.tbl_contains(M.config.rules_filenames, name)
	end

	local function add(p)
		p = normalize(clean(p))
		if is_rule_file(p) then
			return
		end
		if p ~= "" and not seen[p] and p:match("^" .. vim.pesc(proj)) then
			table.insert(out, p)
			seen[p] = true
		end
	end

	-- refs
	for _, r in ipairs(chat.refs or {}) do
		if is_file_ref(r) then
			add(r.path ~= "" and r.path or id_to_path(r.id))
		end
	end

	-- messages
	for _, msg in ipairs(chat.messages) do
		if msg.opts and msg.opts.reference then
			local p = msg.opts.reference:match("^<file>([^<]+)</file>$")
			if p then
				add(p)
			end
		end
		if msg.content then
			for p in msg.content:gmatch("^%*%*Insert Edit Into File Tool%*%*: `([^`]+)`") do
				add(p)
			end
			for p in msg.content:gmatch("^%*%*Create File Tool%*%*: `([^`]+)`") do
				add(p)
			end
			for p in msg.content:gmatch("^%*%*Read File Tool%*%*: Lines %d+ to %-?%d+ of ([^:]+):") do
				add(p)
			end
		end
		local cb = M.config.extract_file_paths_from_chat_message
		if type(cb) == "function" then
			local ok, extra = pcall(cb, msg)
			if ok and type(extra) == "table" then
				for _, p in ipairs(extra) do
					add(p)
				end
			end
		end
	end

	log(("collect_paths -> %d path(s)"):format(#out))
	return out
end

--──────────────────────────────────────────────────────────────────────────────
--  Ascend directories to find rule files
--──────────────────────────────────────────────────────────────────────────────
local function collect_rules(paths)
	if not M.config.enabled then
		return {}
	end
	local proj = normalize(vim.fn.getcwd())
	local out, seen = {}, {}

	local function ascend(dir)
		dir = normalize(dir)
		while dir ~= "/" and dir:match("^" .. vim.pesc(proj)) do
			local f = find_first_file(dir, M.config.rules_filenames)
			if f and not seen[f] then
				out[#out + 1] = f
				seen[f] = true
			end
			local parent = vim.fn.fnamemodify(dir, ":h")
			if parent == dir then
				break
			end
			dir = parent
		end
	end

	for _, p in ipairs(paths) do
		ascend(vim.fn.fnamemodify(p, ":h"))
	end

	table.sort(out, function(a, b)
		return select(2, a:gsub("/", "")) > select(2, b:gsub("/", ""))
	end)
	log(("collect_rules -> %d rule file(s)"):format(#out))
	return out
end

--──────────────────────────────────────────────────────────────────────────────
--  Sync chat.refs with rule files (dedup, attach, remove)
--──────────────────────────────────────────────────────────────────────────────
local function sync_refs(bufnr, rule_files)
	if not M.config.enabled then
		return
	end
	local chat = require("codecompanion.strategies.chat").buf_get_chat(bufnr)
	if not chat then
		return
	end

	-- (rest of sync_refs unchanged) ...
	local desired = {}
	for _, rf in ipairs(rule_files) do
		local rel = vim.fn.fnamemodify(rf, ":.")
		desired["<file>" .. rel .. "</file>"] = rel
	end

	local existing = {}
	for i = #chat.refs, 1, -1 do
		local r = chat.refs[i]
		if type(r.id) == "string" and r.id:match("^<file>") then
			if existing[r.id] then
				table.remove(chat.refs, i)
			else
				existing[r.id] = r
			end
		end
	end

	local added, removed = false, false
	local added_count, removed_count = 0, 0

	for id, rel in pairs(desired) do
		if not existing[id] then
			local file_mod = require("codecompanion.strategies.chat.slash_commands.file")
			file_mod.new({ Chat = chat }):output({ path = rel }, { rules_managed = true, pinned = true })
			local last_ref = chat.refs[#chat.refs]
			if last_ref and last_ref.id == id then
				last_ref.opts = last_ref.opts or {}
				last_ref.opts.rules_managed = true
				last_ref.opts.pinned = true
			end
			added = true
			added_count = added_count + 1
		else
			local r = existing[id]
			if r.opts and r.opts.rules_managed and not r.opts.pinned then
				r.opts.pinned = true
			end
		end
	end

	for i = #chat.refs, 1, -1 do
		local r = chat.refs[i]
		if r.opts and r.opts.rules_managed and not desired[r.id] then
			local ref_id = r.id
			table.remove(chat.refs, i)
			for j = #chat.messages, 1, -1 do
				local m = chat.messages[j]
				if m.opts and m.opts.reference == ref_id then
					table.remove(chat.messages, j)
				end
			end
			removed = true
			removed_count = removed_count + 1
		end
	end

	if added or removed then
		log(("sync_refs -> added:%s removed:%s"):format(tostring(added), tostring(removed)))
		local msg = {}
		if added_count > 0 then
			table.insert(msg, ("Added %d rule reference(s)"):format(added_count))
		end
		if removed_count > 0 then
			table.insert(msg, ("Removed %d obsolete rule reference(s)"):format(removed_count))
		end
		if #msg > 0 then
			notify(table.concat(msg, ", "))
		end
	else
		log("sync_refs -> no change")
		return
	end

	-- re-render context block
	local start = chat.header_line + 1
	local last = vim.api.nvim_buf_line_count(chat.bufnr)
	local i = start
	while i < last do
		local l = vim.api.nvim_buf_get_lines(chat.bufnr, i, i + 1, false)[1] or ""
		if l == "" or l:match("^") then
			i = i + 1
		else
			break
		end
	end
	if i > start then
		vim.api.nvim_buf_set_lines(chat.bufnr, start, i, false, {})
	end
	if chat.references and chat.references.render then
		chat.references:render()
	end
end

--──────────────────────────────────────────────────────────────────────────────
--  Main worker
--──────────────────────────────────────────────────────────────────────────────
local function process(bufnr)
	if not M.config.enabled then
		return
	end
	log("process -> begin")
	local paths = collect_paths(bufnr)
	local fp = hash(paths)

	if fingerprint[bufnr] == fp then
		log("process -> fingerprint unchanged, skipping")
		return
	end
	fingerprint[bufnr] = fp

	sync_refs(bufnr, collect_rules(paths))
	log("process -> done")
end

--──────────────────────────────────────────────────────────────────────────────
--  Event handlers
--──────────────────────────────────────────────────────────────────────────────
local function on_mode(bufnr)
	if not M.config.enabled then
		return
	end
	enabled[bufnr] = true
	process(bufnr)
end
local function on_submit(bufnr)
	if not M.config.enabled then
		return
	end
	process(bufnr)
end
local function on_tool(bufnr)
	if not M.config.enabled then
		return
	end
	process(bufnr)
end
local function on_clear(bufnr)
	enabled[bufnr], fingerprint[bufnr] = nil, nil
end

--──────────────────────────────────────────────────────────────────────────────
--  Setup
--──────────────────────────────────────────────────────────────────────────────
function M.setup(opts)
	if opts then
		M.config = vim.tbl_deep_extend("force", M.config, opts)
	end

	local grp = vim.api.nvim_create_augroup("CodeCompanionRules", { clear = true })

	vim.api.nvim_create_autocmd("User", {
		group = grp,
		pattern = "CodeCompanionChatCreated",
		callback = function()
			on_mode(vim.api.nvim_get_current_buf())
		end,
	})

	vim.api.nvim_create_autocmd("ModeChanged", {
		group = grp,
		pattern = "i:n",
		callback = function()
			if vim.bo.filetype == "codecompanion" then
				on_mode(vim.api.nvim_get_current_buf())
			end
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		group = grp,
		pattern = "CodeCompanionChatSubmitted",
		callback = function()
			on_submit(vim.api.nvim_get_current_buf())
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		group = grp,
		pattern = { "CodeCompanionToolFinished", "CodeCompanionChatStopped" },
		callback = function()
			on_tool(vim.api.nvim_get_current_buf())
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		group = grp,
		pattern = { "CodeCompanionChatCleared", "CodeCompanionChatClosed" },
		callback = function()
			on_clear(vim.api.nvim_get_current_buf())
		end,
	})

	vim.api.nvim_create_user_command("CodeCompanionRulesProcess", function()
		on_mode(vim.api.nvim_get_current_buf())
	end, { desc = "Re-evaluate rule references now" })

	vim.api.nvim_create_user_command("CodeCompanionRulesDebug", function()
		M.config.debug = not M.config.debug
		log("CodeCompanion-Rules debug = " .. tostring(M.config.debug))
	end, { desc = "Toggle rules debug" })

	-- enable/disable commands
	vim.api.nvim_create_user_command("CodeCompanionRulesEnable", function()
		M.config.enabled = true
		notify("Extension enabled")
		on_mode(vim.api.nvim_get_current_buf())
	end, { desc = "Enable CodeCompanion-Rules extension" })

	vim.api.nvim_create_user_command("CodeCompanionRulesDisable", function()
		M.config.enabled = false
		-- clear all per-buffer caches
		for bufnr in pairs(enabled) do
			enabled[bufnr] = nil
		end
		for bufnr in pairs(fingerprint) do
			fingerprint[bufnr] = nil
		end
		notify("Extension disabled")
	end, { desc = "Disable CodeCompanionRules extension" })
end

return M
