local log = require("rush.log")
local KeyEvent = require("keyevent.keyevent")

local M = {}

--------------------------------------------------
-- constants
--------------------------------------------------

local RUSH_VIM_COUNT = -1
local RUSH_NONE = 0

--------------------------------------------------
-- default config
--------------------------------------------------

local key_set = { "h", "j", "k", "l", "w", "b", "e", "W", "B", "E", }
local default_config = {
	interval = { rep1 = 66, rep2 = 98, hold1 = 490, hold2 = 510, tap = 1000, },
	rush_count = { "vim", 2, 4, 8, 16, 32, 64, },
}

local config
local rush_count

--------------------------------------------------
-- config
--------------------------------------------------

---@alias RushCountValue "vim"|"none"|integer

---@param values RushCountValue[]
---@return any[]
local function make_rush_count(values)
	if type(values) ~= "table" then
		error("rush_count must be a table")
	end

	local result = {}
	for _, value in ipairs(values) do
		if value == "vim" then
			table.insert(result, RUSH_VIM_COUNT)
		elseif value == "none" then
			table.insert(result, RUSH_NONE)
		elseif
			type(value) == "number"
			and value >= 1
			and value == math.floor(value)
		then
			table.insert(result, value)
		else
			error(("invalid rush_count value: %s"):format(vim.inspect(value)))
		end
	end
	return result
end

---@param opts table
local function setup_config(opts)
	config =
		vim.tbl_deep_extend("force", vim.deepcopy(default_config), opts or {})
	rush_count = make_rush_count(config.rush_count)
end

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

---@param event KeyEvent
---@return string
local function get_new_motion(event)
	return get_count(event) .. event.key
end

--------------------------------------------------
-- event processing
--------------------------------------------------

---@param typed string
local function on_key(_, typed)
	if #typed == 0 then
		return
	end
	if not vim.tbl_contains(key_set, typed) then
		KeyEvent.on_key_event(typed)
	end
end

--------------------------------------------------
-- setupgv
--------------------------------------------------

---@param opts? table
function M.setup(opts)
	setup_config(opts or {})
	for _, motion in ipairs(key_set) do
		vim.keymap.set({ "n", "x" }, motion, function()
			local keyevent = KeyEvent.keymap_event(motion)
			return get_new_motion(keyevent)
		end, { expr = true })
	end
end

vim.on_key(on_key)

return M
