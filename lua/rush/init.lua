local keyevent = require("keyevent.keyevent")
local log = require("keyevent.log")

local M = {}

local META = keyevent.meta()

---@enum RushState
local STATE = {
	INIT = "init",
	NORMAL = "normal",
	REPEAT = "repeat",
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

-- attribute
local state = STATE.INIT
local vim_count = 1
local level = 0
local share_key = ""
local share_count = 0

local saved_keymaps = nil
local rush_motions = {}

---@param event KeyEvent
local function is_reverse_key(event)
	return rush_keys[event.key] == event.prev_key
end

local function is_share_key(event)
	return event.key == share_key or event.key == rush_keys[share_key]
end

---@param event KeyEvent
---@return integer
local function get_count_normal(event)
	if is_share_key(event) then
		return share_count == 0 and 1 or share_count
	else
		return 1
	end
end

---@param event KeyEvent
---@return integer
local function get_count_rush(event)
	local scale
	if level >= 0 then
		scale = 2 ^ level
	else
		scale = -2 ^ (-level - 1)
	end
	return math.max(vim_count, share_count, 1) * scale
end

---@param event KeyEvent
---@return integer
local function get_count(event)
	if event.nr <= 1 then
		return get_count_normal(event)
	else
		return get_count_rush(event)
	end
end

---@param event KeyEvent
---@return string
local function get_new_motion(event)
	local count = get_count(event)
	local key = event.key
	if count < 0 then
		key = rush_keys[event.key]
		count = -count
	end
	if count == 1 then
		return key
	else
		return count .. key
	end
end

---@param event KeyEvent
---@param new_motion string
local function debug_event(event, new_motion)
	log.watch("RSH", "%7s %3s %s", state, new_motion, keyevent.to_string(event))
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
			return M._key_process(motion)
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
	if new_state == STATE.REPEAT then
		if not saved_keymaps then
			set_metakeymaps()
		end
	else
		if saved_keymaps then
			remove_metakeymap(saved_keymaps.bufnr)
			restore_metakeymaps(saved_keymaps.bufnr, saved_keymaps.maps)
			saved_keymaps = nil
		end
	end
	state = new_state
end

---@param event KeyEvent|nil
local function set_share(event)
	if event then
		share_key = event.key
		share_count = vim_count
	else
		share_key = ""
		share_count = 0
	end
end

---@param event KeyEvent
local function process_init(event)
	level = 0
	vim_count = vim.v.count
	if vim_count ~= 0 then
		set_share()
	end
	transition(STATE.NORMAL)
end

---@param event KeyEvent
---@return boolean
local function is_share_event(event)
	if vim_count == 0 then
		return false
	end
	if event.nt ~= 2 then
		return false
	end
	local event3 = keyevent.peek(3)
	return event3.prev_key:match("^%d+$")
end

---@param event KeyEvent
local function check_share(event)
	if is_share_event(event) then
		level = level - 1
		set_share(event)
	end
end

---@param event KeyEvent
local function process_normal(event)
	if event.type == keyevent.KEY_EVENT_TYPE.REPEAT then
		check_share(event)
		if event.ng_repeat ~= 0 then
			level = level - 1
			event.nr = event.ng_repeat + 1
		end
		transition(STATE.REPEAT)
		return
	end
	if event.nt <= 1 then
		level = 0
	else
		level = level + 1
	end
end

---@param event KeyEvent
local function process_repeat_meta(event)
	if event.meta == event.prev_meta then
		return
	end
	if event.meta == accelerate.forward then
		level = level + 1
	elseif event.meta == accelerate.backward then
		level = level - 1
	end
end

---@param event KeyEvent
local function process_repeat_tap(event)
	if keyevent.is_same_key(event) then
		level = level + 1
	elseif is_reverse_key(event) then
		level = -level
	else
		level = 0
	end
end

---@param event KeyEvent
local function process_repeat(event)
	if event.ng_repeat ~= 0 then
		if event.ng_repeat == 1 then
			level = level + 1
		end
		event.nr = event.ng_repeat + 1
	end
	if event.type == keyevent.KEY_EVENT_TYPE.REPEAT then
		process_repeat_meta(event)
		return
	end
	if event.type == keyevent.KEY_EVENT_TYPE.TAP then
		process_repeat_tap(event)
	else
		level = 0
	end
	transition(STATE.NORMAL)
end

--  | state | event | next state | action |  |
--  |  |  |  | level |  |
--  | INIT | CTR | -> NORMAL | 0 | vim_count |
--  | NORMAL | R | -> REPEAT | - | share_count |
--  |  | CT nt<=1 | - | - |  |
--  |  | T  nt>=2 | - | up |  |
--  | REPEAT | R | - | - | check_meta |
--  |  | T+ | -> NORMAL | up |  |
--  |  | T- | -> NORMAL | reverse |  |
--  |  | Tx | -> NORMAL | 0 |  |
--  |  | C | -> NORMAL | 0 |  |
---@param event KeyEvent
local function process_event(event)
	if event.ng_repeat ~= 0 then
		event.type = keyevent.KEY_EVENT_TYPE.REPEAT
	end
	if state == STATE.INIT then
		process_init(event)
	elseif state == STATE.NORMAL then
		process_normal(event)
	elseif state == STATE.REPEAT then
		process_repeat(event)
	else
		assert(false, "Invalid state: " .. state)
	end
end

local function test_output(event, new_key)
	if vim.g.kibi2_test_mode == 1 then
		local str = string.format(
			"%7s %3s (%d %d %d) %s",
			state,
			new_key,
			vim_count,
			level,
			share_count,
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

local function initialize_rush_keys()
	for _, set in ipairs(key_pairs) do
		rush_keys[set[1]] = set[2]
		rush_keys[set[2]] = set[1]
	end
end

local function initialize_keymaps()
	for motion, _ in pairs(rush_keys) do
		vim.keymap.set(KEYMAP_MODE, motion, function()
			return M._key_process(motion)
		end, { expr = true })
	end
end

local function initialize_rush_motions()
	rush_motions = {}
	for motion, _ in pairs(rush_keys) do
		for _, meta in ipairs({ accelerate.forward, accelerate.backward }) do
			local motion = keyevent.unparse(motion, meta)
			rush_motions[#rush_motions + 1] = motion
		end
	end
end

local function on_event(event)
	if is_break_or_end(event) or rush_keys[event.key] == nil then
		debug_event(event, "")
		transition(STATE.INIT)
	end
	if event.key == "<Esc>" then
		set_share()
	end
end

local function initialize()
	initialize_rush_keys()
	initialize_keymaps()
	initialize_rush_motions()
	keyevent.on_event(function(event)
		on_event(event)
	end)
end

function M._key_process(motion)
	local event = keyevent.keymap_event(motion)
	process_event(event)
	local new_motion = get_new_motion(event)
	test_output(event, new_motion)
	debug_event(event, new_motion)
	return new_motion
end

function M.setup() end

initialize()

return M
