local M = {}

--------------------------------------------------
-- config
--------------------------------------------------

local key_set = {
	"h",
	"j",
	"k",
	"l",
}

--------------------------------------------------
-- state
--------------------------------------------------

local phase = "measure"

local buf
local win

local prev_key
local prev_time
local first_repeat

local hold_intervals = {}
local repeat_intervals = {}

local display_pending = false

--------------------------------------------------
-- utility
--------------------------------------------------

local function min_value(values)
	if #values == 0 then
		return nil
	end

	local result = values[1]

	for index = 2, #values do
		result = math.min(result, values[index])
	end

	return result
end

local function max_value(values)
	if #values == 0 then
		return nil
	end

	local result = values[1]

	for index = 2, #values do
		result = math.max(result, values[index])
	end

	return result
end

local function format_value(value)
	if value == nil then
		return "-"
	end

	return tostring(value)
end

--------------------------------------------------
-- measurement
--------------------------------------------------

local function measure_key(key)
	local now = vim.loop.hrtime()

	if prev_key ~= key or prev_time == nil then
		prev_key = key
		prev_time = now
		first_repeat = true
		return
	end

	local delta_t = math.floor((now - prev_time) / 1e6 + 0.5)

	if first_repeat then
		table.insert(hold_intervals, delta_t)
		first_repeat = false
	else
		table.insert(repeat_intervals, delta_t)
	end

	prev_time = now
end

--------------------------------------------------
-- display
--------------------------------------------------

local function suggested_config()
	local rep = max_value(repeat_intervals)
	local hold1 = min_value(hold_intervals)
	local hold2 = max_value(hold_intervals)

	return {
		"  rep   = " .. format_value(rep),
		"  hold1 = " .. format_value(hold1),
		"  hold2 = " .. format_value(hold2),
	}
end

local function make_lines()
	local hold_min = min_value(hold_intervals)
	local hold_max = max_value(hold_intervals)

	local repeat_min = min_value(repeat_intervals)
	local repeat_max = max_value(repeat_intervals)

	local lines = {
		"Rush diagnosis",
		"",
		"Press and hold a key several times.",
		"",
		"Use a different key for each measurement.",
		"For example: hold j hold k hold j hold k",
		"",
		"────────────────────────────────────────",
		"Detected intervals:",
		"",
		"        count   min(ms)   max(ms)",
		string.format(
			"hold    %5d   %7s   %7s",
			#hold_intervals,
			format_value(hold_min),
			format_value(hold_max)
		),
		string.format(
			"repeat  %5d   %7s   %7s",
			#repeat_intervals,
			format_value(repeat_min),
			format_value(repeat_max)
		),
		"",
		"Suggested configuration:",
		"",
	}

	vim.list_extend(lines, suggested_config())

	vim.list_extend(lines, {
		"",
		"────────────────────────────────────────",
		"",
		phase == "measure" and "Press <Esc> to finish."
			or "Press <Esc> to close.",
	})

	return lines
end

local function show()
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, make_lines())
end

local function schedule_show()
	if display_pending then
		return
	end

	display_pending = true

	vim.schedule(function()
		display_pending = false

		if phase == "closed" then
			return
		end

		show()
	end)
end

--------------------------------------------------
-- float
--------------------------------------------------

local function create_window()
	buf = vim.api.nvim_create_buf(false, true)

	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = true

	local width = 64
	local height = 28

	local ui = vim.api.nvim_list_uis()[1]

	local row = math.floor((ui.height - height) / 2)
	local col = math.floor((ui.width - width) / 2)

	win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		row = row,
		col = col,
		width = width,
		height = height,
		style = "minimal",
		border = "rounded",
	})

	vim.wo[win].wrap = false
	vim.wo[win].cursorline = false
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"

	show()
end

--------------------------------------------------
-- cleanup
--------------------------------------------------

local function close()
	phase = "closed"

	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end

	win = nil
	buf = nil
end

--------------------------------------------------
-- keymaps
--------------------------------------------------

local function setup_keymaps()
	for _, key in ipairs(key_set) do
		vim.keymap.set("n", key, function()
			measure_key(key)
			schedule_show()

			-- Important:
			-- Let the key actually operate on the buffer.
			return key
		end, {
			buffer = buf,
			expr = true,
			silent = true,
		})
	end

	vim.keymap.set("n", "<Esc>", function()
		if phase == "measure" then
			phase = "result"
			schedule_show()
		else
			close()
		end

		return ""
	end, {
		buffer = buf,
		expr = true,
		silent = true,
	})
end

--------------------------------------------------
-- public
--------------------------------------------------

function M.start()
	if win and vim.api.nvim_win_is_valid(win) then
		return
	end

	phase = "measure"

	prev_key = nil
	prev_time = nil
	first_repeat = true

	hold_intervals = {}
	repeat_intervals = {}

	display_pending = false

	create_window()
	setup_keymaps()
end

return M
