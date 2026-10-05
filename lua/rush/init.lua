local config = require("keyevent.config")
local keyevent = require("keyevent.keyevent")
local bitflag = require("keyevent.bitflag")
local log = require("keyevent.log")

local M = {}

local META = keyevent.meta()

---@enum RushState
local STATE = {
	NORMAL = "normal",
	HOLD1 = "hold1",
	HOLD2 = "hold2",
}

local KEYMAP_MODE = { "n", "x" }

local key_pairs = {
	{ "h", "l" },
	{ "j", "k" },
	{ "w", "b" },
	-- {"e", "ge"},
}
local rush_keys = {}
local accelerate = {
	forward = META.C,
	backward = META.A,
}

local state = STATE.NORMAL
local rush_count = 0
local saved_keymaps
local rush_motions = {}

---@param event KeyEvent
---@return integer
local function get_count(event)
	if event.nr == 1 and event.nh == 1 then
		-- If a tap is mistakenly recognized as a hold,
		-- it can cause incorrect behavior, so we wait for the next repeat
		return 1
	end
	return math.abs(rush_count)
end

---@return string
local function get_key(event)
	if rush_count < 0 then
		return key_pairs[event.key]
	end
	return event.key
end

---@param event KeyEvent
---@return string
local function get_new_motion(event)
	if state == STATE.NORMAL then
		return event.key
	end
	local count = get_count(event)
	if count == 0 then
		return ""
	elseif count == 1 then
		return get_key(event)
	else
		return count .. get_key(event)
	end
end

local function debug_event(event)
	log.watch(
		"RSH",
		"%7s %3s %s",
		state,
		get_new_motion(event),
		keyevent.to_string(event)
	)
end

local function increase1()
	if rush_count < 0 then
		rush_count = math.modf(rush_count / 2)
		if rush_count == 0 then
			rush_count = 1
		end
	else
		rush_count = rush_count * 2
	end
end

---@param level integer
local function increase(level)
	for _ = 1, level do
		increase1()
	end
end

local function decrease1()
	if rush_count < 0 then
		rush_count = rush_count * 2
	else
		rush_count = math.modf(rush_count / 2)
		if rush_count == 0 then
			rush_count = -1
		end
	end
end

---@param level integer
local function decrease(level)
	for _ = 1, level do
		decrease1()
	end
end

---@param key string
local function save_keymap(maps, key)
	for _, map in ipairs(maps) do
		if keyevent.is_same_key_notation(map.lhs, key) then
			return map
		end
	end
end

---@param bufnr number
local function save_keymaps(bufnr)
	local save = {}
	for _, mode in ipairs(KEYMAP_MODE) do
		local maps = vim.api.nvim_buf_get_keymap(bufnr, mode)
		for _, key in ipairs(rush_motions) do
			save[#save + 1] = save_keymap(maps, key)
		end
	end
	saved_keymaps = {
		bufnr = bufnr,
		maps = save,
	}
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

---@param bufnr integer
local function remove_metakeymap(bufnr)
	for _, motion in ipairs(rush_motions) do
		for _, mode in ipairs(KEYMAP_MODE) do
			local ok, result =
				pcall(vim.keymap.del, mode, motion, { buffer = bufnr })
			if not ok then
				log.error({ mode, motion, bufnr })
				log.error(result)
			end
		end
	end
end

local function restore_keymap(bufnr, map)
	local original = map
	local rhs = original.callback or original.rhs
	vim.keymap.set(original.mode, original.lhs, rhs, {
		buffer = original.buffer == 1 and bufnr or nil,
		expr = original.expr == 1,
		silent = original.silent == 1,
		noremap = original.noremap == 1,
		nowait = original.nowait == 1,
		desc = original.desc,
	})
end

local function restore_metakeymaps(bufnr, maps)
	for _, map in ipairs(maps) do
		restore_keymap(bufnr, map)
	end
end

---@param new_state RushState
local function transition(new_state)
	if state == STATE.NORMAL and new_state == STATE.HOLD1 then
		set_metakeymaps()
	elseif state ~= STATE.NORMAL and new_state == STATE.NORMAL then
		if saved_keymaps then
			remove_metakeymap(saved_keymaps.bufnr)
			restore_metakeymaps(saved_keymaps.bufnr, saved_keymaps.maps)
			saved_keymaps = nil
		end
		-- Reset rush count for the next normal motion.
		rush_count = 1
	end
	state = new_state
end

---@param event KeyEvent
local function check_transition(event)
	if state == STATE.NORMAL then
		if event.nr == 1 then
			transition(STATE.HOLD1)
		end
	elseif state == STATE.HOLD1 then
		if event.nr == 1 then
			transition(STATE.HOLD2)
		end
	end
	if state ~= STATE.NORMAL then
		if
			not keyevent.is_same_key(event)
			or event.type == keyevent.KEY_EVENT_TYPE.CLICK
		then
			transition(STATE.NORMAL)
		end
	end
end

---@param event KeyEvent
local function process_normal(event)
	if not keyevent.is_same_key(event) then
		rush_count = vim.v.count1
	end
end

---@param event KeyEvent
local function process_rush(event)
	if state == STATE.HOLD1 then
		if event.nr == 1 then
			rush_count = rush_count * 2 ^ (event.nt - 1)
		end
	elseif state == STATE.HOLD2 then
		if event.nr == 1 then
			increase(event.nt)
		end
	end
	if
		bitflag.is_off(event.prev_meta, accelerate.forward)
		and bitflag.is_on(event.meta, accelerate.forward)
	then
		increase(1)
	end
	if
		bitflag.is_off(event.prev_meta, accelerate.backward)
		and bitflag.is_on(event.meta, accelerate.backward)
	then
		decrease(1)
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

local function test_output(event, new_key)
	if vim.g.kibi2_test_mode == 1 then
		local str = string.format(
			"%7s %3s %s",
			state,
			new_key,
			keyevent.to_string(event)
		)
		print(str)
	end
end

---@param event KeyEvent
---@return boolean
local function is_break_or_end(event)
	return event.type == keyevent.KEY_EVENT_TYPE.BREAK
		or event.type == keyevent.KEY_EVENT_TYPE.REPEAT_END
end

local function initialize()
	for _, set in ipairs(key_pairs) do
		rush_keys[set[1]] = set[2]
		rush_keys[set[2]] = set[1]
	end
	log.probe(rush_keys)
	for motion, _ in pairs(rush_keys) do
		vim.keymap.set(KEYMAP_MODE, motion, function()
			return M.key_process(motion)
		end, { expr = true })
	end
	rush_motions = {}
	for motion, _ in pairs(rush_keys) do
		for _, meta in ipairs({ accelerate.forward, accelerate.backward }) do
			local motion = keyevent.unparse(motion, meta)
			rush_motions[#rush_motions + 1] = motion
		end
	end
	keyevent.on_event(function(event)
		if is_break_or_end(event) or rush_keys[event.key] == nil then
			debug_event(event)
			transition(STATE.NORMAL)
		end
	end)
end

function M.key_process(motion)
	local event = keyevent.keymap_event(motion)
	process_event(event)
	debug_event(event)
	local new_motion = get_new_motion(event)
	test_output(event, new_motion)
	return new_motion
end

function M.setup() end

initialize()

return M
