local log = require("rush.log")
local KeyEvent = require("keyevent.keyevent")

local M = {}

---@enum RushState
local STATE = {
	NORMAL = "normal",
	HOLD1 = "hold1",
	HOLD2 = "hold2",
}

local KEYMAP_MODE = { "n", "x" }

local key_sets = {
	h = "l",
	j = "k",
	k = "j",
	l = "h",
	w = "b",
	b = "w",
	e = "ge",
}
local accelerate = {
	forward = KeyEvent.KEY_EVENT_META_MASK.C,
	backward = KeyEvent.KEY_EVENT_META_MASK.A,
}

local state = STATE.NORMAL
local rush_count = 0
local saved_keymaps = {}
local rush_motions

---@return integer
local function get_count()
	return math.abs(rush_count)
end

---@return string
local function get_key(event)
	if rush_count < 0 then
		return key_sets[event.key]
	end
	return event.key
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
		"%7s %3s %s",
		state,
		get_new_motion(event),
		KeyEvent.to_string(event)
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

---@param key string
local function save_keymap(bufnr, mode, key)
	local maps = vim.api.nvim_buf_get_keymap(bufnr, mode)
	for _, map in ipairs(maps) do
		if KeyEvent.is_same_key_notation(map.lhs, key) then
			return map
		end
	end
end

---@param bufnr number
local function save_keymaps(bufnr)
	local save = {}
	for _, key in ipairs(rush_motions) do
		for _, mode in ipairs(KEYMAP_MODE) do
			save[#save + 1] = save_keymap(bufnr, mode, key)
		end
	end
	saved_keymaps[bufnr] = save
end

local function set_metakeymaps()
	local bufnr = vim.api.nvim_get_current_buf()
	save_keymaps(bufnr)
	for _, motion in ipairs(rush_motions) do
		vim.keymap.set(KEYMAP_MODE, motion, function()
			return M.key_process(motion)
		end, { expr = true, buffer = bufnr })
	end
end

local function remove_metakeymap()
	local bufnr = vim.api.nvim_get_current_buf()
	for _, motion in ipairs(rush_motions) do
		for _, mode in ipairs(KEYMAP_MODE) do
			local ok, result =
				pcall(vim.keymap.del, mode, motion, { buffer = bufnr })
			if not ok then
				log.probe({ mode, motion, bufnr })
				log.probe(result)
			end
		end
	end
end

local function restore_keymaps(map)
	local rhs = map.callback or map.rhs
	vim.keymap.set(map.mode, map.lhs, rhs, {
		buffer = map.bufnr,
		expr = map.expr == 1,
		silent = map.silent == 1,
		noremap = map.noremap == 1,
		nowait = map.nowait == 1,
		desc = map.desc,
	})
end

local function restore_metakeymaps()
	local bufnr = vim.api.nvim_get_current_buf()
	for _, map in ipairs(saved_keymaps[bufnr]) do
		restore_keymaps(map)
	end
	saved_keymaps[bufnr] = nil
end

---@param new_state RushState
local function transition(new_state)
	if state == STATE.NORMAL and new_state == STATE.HOLD1 then
		set_metakeymaps()
	elseif state ~= STATE.NORMAL and new_state == STATE.NORMAL then
		remove_metakeymap()
		restore_metakeymaps()
		rush_count = 1
	end
	state = new_state
end

---@param event KeyEvent
local function check_transition(event)
	if state == STATE.NORMAL then
		if event.nr == 2 then
			transition(STATE.HOLD1)
		end
	elseif state == STATE.HOLD1 then
		if event.nr == 1 then
			transition(STATE.HOLD2)
		end
	end
	if state ~= STATE.NORMAL then
		if
			not KeyEvent.is_same_key(event)
			or event.type == KeyEvent.KEY_EVENT_TYPE.CLICK
		then
			transition(STATE.NORMAL)
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
	if state == STATE.HOLD1 then
		if event.nr == 2 then
			rush_count = rush_count * 2 ^ (event.nt - 1)
		end
	elseif state == STATE.HOLD2 then
		if event.nr == 1 then
			if event.nt == 1 then
				increase()
			else
				decrease()
			end
		end
	end
	if
		KeyEvent.is_off(event.prev_meta, accelerate.forward)
		and KeyEvent.is_on(event.meta, accelerate.forward)
	then
		increase()
	end
	if
		KeyEvent.is_off(event.prev_meta, accelerate.backward)
		and KeyEvent.is_on(event.meta, accelerate.backward)
	then
		decrease()
	end
end

---@param event KeyEvent
local function process_event(event)
	check_transition(event)
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
	for motion, _ in pairs(key_sets) do
		vim.keymap.set(KEYMAP_MODE, motion, function()
			return M.key_process(motion)
		end, { expr = true })
	end
	rush_motions = {}
	for motion, _ in pairs(key_sets) do
		for _, meta in ipairs({ accelerate.forward, accelerate.backward }) do
			local motion = KeyEvent.unparse(motion, meta)
			rush_motions[#rush_motions + 1] = motion
		end
	end
end

KeyEvent.on_event(function(event)
	if event.type == KeyEvent.KEY_EVENT_TYPE.REPEAT_END then
		debug_event(event)
		transition(STATE.NORMAL)
	end
end)

return M
