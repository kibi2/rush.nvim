local log = require("rush.log")
local KeyEvent = require("keyevent.keyevent")

local M = {}

---@enum RushState
local STATE = {
	NORMAL = "normal",
	RUSH = "rush",
}

local key_set = { "h", "j", "k", "l", "w", "b", "e", "W", "B", "E" }

local state = STATE.NORMAL
local rush_count = 0

---@return integer
local function get_count()
	return math.abs(rush_count)
end

---@return string
local function get_key(event)
	return event.key
end

---@param new_state RushState
local function transition(new_state)
	state = new_state
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

---@param event KeyEvent
local function process_normal(event)
	if event.nr == 1 then
		transition(STATE.RUSH)
		rush_count = rush_count * 2 ^ (event.nt - 1)
	end
end

---@param event KeyEvent
local function process_rush(event)
	if not KeyEvent.is_same_key(event) or event.type == KeyEvent.KEY_EVENT.CLICK then
		transition(STATE.NORMAL)
	end
	if event.nt == 1 and event.nr == 0 then
	elseif event.nt == 1 and event.nr == 1 then
		rush_count = math.floor(rush_count / 2)
	elseif event.nt > 1 and event.nr == 0 then
		rush_count = rush_count * 2
	end
end

---@param event KeyEvent
local function process_event(event)
	if not KeyEvent.is_same_key(event) or event.type == KeyEvent.KEY_EVENT.CLICK then
		rush_count = vim.v.count1
	end
	if state == STATE.NORMAL then
		process_normal(event)
	else
		process_rush(event)
	end
end

function M.setup()
	-- setup_config(opts or {})
	for _, motion in ipairs(key_set) do
		vim.keymap.set({ "n", "x" }, motion, function()
			local event = KeyEvent.keymap_event(motion)
			process_event(event)
			log.probe("%s %s %d %s", KeyEvent.to_string(event), state, rush_count, get_new_motion(event))
			return get_new_motion(event)
		end, { expr = true })
	end
end

return M
