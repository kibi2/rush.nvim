local log = require("rush/log")

local M = {}

---@enum State
local STATE = { START = "start", CLICK = "click", TAP = "tap", HOLD = "hold" }
---@enum Event
local EVENT = {
	CLICK = "click",
	TAP = "tap",
	HOLD_START = "hold_start",
	HOLD_REPEAT = "hold_repeat",
}

local state = STATE.START
local prev_key = ""
local prev_time = 0
local first_count = 0
local tap_count = 0
local interval = { rep = 95, hold1 = 490, hold2 = 510, tap = 1000 }
local key_set = {
	"h",
	"j",
	"k",
	"l",
	"w",
	"b",
	"e",
	"W",
	"B",
	"E",
}
local RUSH_VIM_COUNT = -1
local rush_count = { RUSH_VIM_COUNT, 5, 10, 20 }

---@param typed string
---@param delta_t number
---@return Event
local function get_event(typed, delta_t)
	if prev_key ~= typed then
		return EVENT.CLICK
	elseif delta_t <= interval.rep then
		return EVENT.HOLD_REPEAT
	elseif interval.hold1 <= delta_t and delta_t <= interval.hold2 then
		return EVENT.HOLD_START
	elseif delta_t <= interval.tap then
		return EVENT.TAP
	else
		return EVENT.CLICK
	end
end

---@param state State
local function state_exit(state) end

---@param state State
local function state_enter(state)
	if state == STATE.CLICK then
		first_count = vim.v.count
		tap_count = 1
	elseif state == STATE.TAP then
		tap_count = tap_count + 1
	end
end

---@param new_state State
local function transition(new_state)
	state_exit(state)
	state = new_state
	state_enter(state)
end

---@return string
local function get_count()
	if state ~= STATE.HOLD then
		return ""
	end
	local count = rush_count[tap_count] or rush_count[#rush_count]
	if count == 0 then
		return ""
	elseif count == RUSH_VIM_COUNT then
		if first_count == 0 then
			return ""
		else
			return tostring(first_count)
		end
	end
	return tostring(count)
end

---@return string
local function get_new_motion()
	return get_count() .. prev_key
end

---@param event Event
local function process_event(event)
	if state == STATE.START then
		transition(STATE.CLICK)
	elseif state == STATE.CLICK then
		if event == EVENT.CLICK then
			transition(STATE.CLICK)
		elseif event == EVENT.TAP then
			transition(STATE.TAP)
		elseif event == EVENT.HOLD_START then
			transition(STATE.HOLD)
		end
	elseif state == STATE.TAP then
		if event == EVENT.TAP then
			transition(STATE.TAP)
		elseif event == EVENT.HOLD_START then
			transition(STATE.HOLD)
		else
			transition(STATE.CLICK)
		end
	elseif state == STATE.HOLD then
		if event ~= EVENT.HOLD_REPEAT then
			transition(STATE.CLICK)
		end
	end
end

---@param typed string
---@return number
local function key_in(typed)
	local now = vim.loop.hrtime()
	local delta_t = (now - prev_time) / 1e6
	local event = get_event(typed, delta_t)
	process_event(event)
	prev_key = typed
	prev_time = now
	return delta_t
end

---@param key string
---@param typed string
local function on_key(key, typed)
	if #typed == 0 then
		return
	end
	if not vim.tbl_contains(key_set, typed) then
		key_in(typed)
	end
end

---@param opts {[string]:any}
function M.setup(opts)
	opts = opts or {}
	vim.on_key(on_key)
	for _, motion in ipairs(key_set) do
		vim.keymap.set({ "n", "x" }, motion, function()
			local delta_t = key_in(motion)
			log.probe(
				"%s\t: %d, %d\t%s [%d]",
				state,
				first_count,
				tap_count,
				get_new_motion(),
				delta_t
			)
			return get_new_motion()
		end, { expr = true })
	end
end

return M
