local log = require("rush.log")
local KeyEvent = require("keyevent.keyevent")

local M = {}

---@enum RushState
local STATE = {
	NORMAL = "normal",
	RUSH = "rush",
}

local KEYMAP_MODE = { "n", "x" }

local key_sets = {
	{ "h", "l" },
	{ "j", "k" },
	{ "k", "j" },
	{ "l", "h" },
	{ "w", "b" },
	{ "b", "w" },
	{ "e", "ge" },
}
local accele = { 
	forward = KeyEvent.KEY_EVENT_META_MASK.C,
	backward = KeyEvent.KEY_EVENT_META_MASK.A,
}

local state = STATE.NORMAL
local rush_count = 0
local saved_keymaps = {}

---@return integer
local function get_count()
	return math.abs(rush_count)
end

---@return string
local function get_key(event)
	if rush_count < 0 then
		for _, key_set in ipairs(key_sets) do
			if event.key == key_set[1] then
				return key_set[2]
			end
		end
	end
	return event.key
end

---@param key string
local function save_keymap(bufnr, mode, key)
	saved_keymaps[bufnr][key] = saved_keymaps[bufnr][key] or {}
	local maps = vim.api.nvim_buf_get_keymap(bufnr, mode)
	for _, map in ipairs(maps) do
		if map.lhs == key then
			saved_keymaps[bufnr][key][mode] = map
			return
		end
	end
end

---@param key string
local function save_keymaps(bufnr, key)
	saved_keymaps[bufnr] = saved_keymaps[bufnr] or {}
	for _, mode in ipairs(KEYMAP_MODE) do
		save_keymap(bufnr, mode, key)
	end
end

local function restore_keymaps(bufnr, key)
	for _, map in ipairs(KEYMAP_MODE) do
		local ok, result = pcall(vim.keymap.del, map, key, {
			buffer = bufnr,
		})
		if not ok then
			log.probe({ map, key, bufnr })
			log.probe(result)
		end
	end
	saved_keymaps[bufnr] = saved_keymaps[bufnr] or {}
	local maps = saved_keymaps[bufnr][key]
	for _, map in ipairs(maps or {}) do
		local rhs = map.callback or map.rhs
		vim.keymap.set(map.mode, map.lhs, rhs, {
			buffer = bufnr,
			expr = map.expr == 1,
			silent = map.silent == 1,
			noremap = map.noremap == 1,
			nowait = map.nowait == 1,
			desc = map.desc,
		})
	end
end

local function restore_metakeymap()
	local bufnr = vim.api.nvim_get_current_buf()
	for _, meta in ipairs({ accele.forward, accele.backward }) do
		for _, key_set in ipairs(key_sets) do
			local motion = KeyEvent.unparse(key_set[1], meta)
			restore_keymaps(bufnr, motion)
		end
	end
	saved_keymaps[bufnr] = {}
end

---@param event KeyEvent
---@return string
local function get_new_motion(event)
	if state == STATE.NORMAL then
		return event.key
	end
	local count = get_count()
	if count == 0 then
		return ""
	elseif count == 1 then
		return get_key(event)
	else
		return count .. get_key(event)
	end
end

local function debug_event(event)
	log.probe(
		"%s %s %d %s",
		KeyEvent.to_string(event),
		state,
		rush_count,
		get_new_motion(event)
	)
end

local function increase()
	if rush_count < 0 then
		rush_count = math.modf(rush_count / 2)
	elseif rush_count == 0 then
		rush_count = 1
	else
		rush_count = rush_count * 2
	end
end

local function decrease()
	if rush_count < 0 then
		rush_count = rush_count * 2
	elseif rush_count == 0 then
		rush_count = -1
	else
		rush_count = math.modf(rush_count / 2)
	end
end

local function set_metakeymap()
	local bufnr = vim.api.nvim_get_current_buf()
	for _, meta in ipairs({ accele.forward, accele.backward }) do
		for _, key_set in ipairs(key_sets) do
			local motion = KeyEvent.unparse(key_set[1], meta)
			if motion then
				save_keymaps(bufnr, motion)
				vim.keymap.set(KEYMAP_MODE, motion, function()
					return M.key_process(motion)
				end, { expr = true, buffer = bufnr })
			end
		end
	end
end

---@param new_state RushState
---@param event KeyEvent
local function transition(new_state, event)
	if state == STATE.NORMAL and new_state == STATE.RUSH then
		set_metakeymap()
		rush_count = rush_count * 2 ^ (event.nt - 1)
	elseif state == STATE.RUSH and new_state == STATE.NORMAL then
		restore_metakeymap()
		rush_count = 1
	end
	state = new_state
end

---@param event KeyEvent
local function check_tranist(event)
	if state == STATE.NORMAL then
		if event.nr == 1 then
			transition(STATE.RUSH, event)
		end
	else
		if
			not KeyEvent.is_same_key(event)
			or event.type == KeyEvent.KEY_EVENT.CLICK
		then
			transition(STATE.NORMAL, event)
		end
	end
end

---@param event KeyEvent
local function process_normal(event)
	if not KeyEvent.is_same_key(event) then
		rush_count = vim.v.count1
	end
end

---@param event KeyEvent
local function process_rush(event)
	if event.nr == 0 then
		increase()
	end
	if KeyEvent.is_off(event.prev_meta , accele.forward) and
			KeyEvent.is_on(event.meta , accele.forward) then
		increase()
	end
	if KeyEvent.is_off(event.prev_meta , accele.backward) and 
			KeyEvent.is_on(event.meta , accele.backward) then
		decrease()
	end
end

---@param event KeyEvent
local function process_event(event)
	check_tranist(event)
	if state == STATE.NORMAL then
		process_normal(event)
	else
		process_rush(event)
	end
end

function M.key_process(motion)
	local event = KeyEvent.keymap_event(motion)
	process_event(event)
	debug_event(event)
	return get_new_motion(event)
end

function M.setup()
	-- setup_config(opts or {})
	for _, key_set in ipairs(key_sets) do
		local motion = key_set[1]
		vim.keymap.set(KEYMAP_MODE, motion, function()
			return M.key_process(motion)
		end, { expr = true })
	end
end

return M
