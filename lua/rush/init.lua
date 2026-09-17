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
local rush_count

---@param event  KeyEvent
---@return string
local function get_count(event)
	if event.type ~= "repeat" then
		return ""
	end
	local count = rush_count[event.nt] or rush_count[#rush_count]
	if count == 0 then
		return ""
	elseif count == RUSH_VIM_COUNT then
		if event.vim_count == 0 then
			return ""
		else
			return tostring(event.vim_count)
		end
	end
	return tostring(count)
end

---@param new_state RushState
---@return string
local function transition(new_state)
	state = new_state
end

---@param event KeyEvent
---@return string
local function get_new_motion(event)
	if state == STATE.NORMAL then
		return event.key
	elseif state == STATE.RUSH then
		return event.key
	end
	-- return get_count(event) .. event.key
end

---@param event KeyEvent
local function process_normal(event)
	if event.nr == 1 then
		transition(STATE.RUSH)
	end
end

---@param event KeyEvent
local function process_rush(event)
	if not KeyEvent.is_same_key(event) or event.type ~= KeyEvent.KEY_EVENT.REPEAT then
		transition(STATE.NORMAL)
	end
end

---@param event KeyEvent
local function process_event(event)
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
			local keyevent = KeyEvent.keymap_event(motion)
			process_event(keyevent)
			log.probe(state)
			return get_new_motion(keyevent)
		end, { expr = true })
	end
end

return M
