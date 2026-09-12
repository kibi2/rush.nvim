local api = vim.api

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

local buf
local win

local measurements = {}
local prev_key = ""
local prev_time = 0
local first_repeat = true
local hold_intervals = {}
local repeat_intervals = {}

--------------------------------------------------
-- window
--------------------------------------------------

local function set_lines(lines)
	if not buf or not api.nvim_buf_is_valid(buf) then
		return
	end

	vim.bo[buf].modifiable = true
	api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
end

local function create_window()
	buf = api.nvim_create_buf(false, true)

	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = false

	local width = 60
	local height = 20

	local ui = api.nvim_list_uis()[1]

	local row = math.floor((ui.height - height) / 2)
	local col = math.floor((ui.width - width) / 2)

	win = api.nvim_open_win(buf, false, {
		relative = "editor",
		row = row,
		col = col,
		width = width,
		height = height,
		style = "minimal",
		border = "rounded",
	})

	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].wrap = false
end

--------------------------------------------------
-- display
--------------------------------------------------

local function show_result()
	local result = {
		rep = math.max(unpack(repeat_intervals)),
		hold1 = math.min(unpack(hold_intervals)),
		hold2 = math.max(unpack(hold_intervals)),
	}

	if not result then
		set_lines({
			"Rush diagnosis",
			"",
			"Not enough measurements.",
			"",
			"Press <Esc> to finish.",
		})
		return
	end

	set_lines({
		"Rush diagnosis",
		"",
		"Detected intervals:",
		"",
		"  repeat",
		string.format("    max: %d ms", result.rep),
		"",
		"  hold",
		string.format("    min: %d ms", result.hold1),
		string.format("    max: %d ms", result.hold2),
		"",
		"Suggested configuration:",
		"",
		string.format("  rep   = %d", result.rep),
		string.format("  hold1 = %d", result.hold1),
		string.format("  hold2 = %d", result.hold2),
	})
end

--------------------------------------------------
-- input
--------------------------------------------------

local function key_in(key)
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
-- cleanup
--------------------------------------------------

local function cleanup()
	for _, key in ipairs(key_set) do
		pcall(vim.keymap.del, "n", key)
		pcall(vim.keymap.del, "x", key)
	end

	if win and api.nvim_win_is_valid(win) then
		api.nvim_win_close(win, true)
	end

	win = nil
	buf = nil
	prev_time = nil
end

--------------------------------------------------
-- public
--------------------------------------------------

function M.start()
	if win and api.nvim_win_is_valid(win) then
		return
	end

	measurements = {}
	prev_time = nil

	create_window()

	set_lines({
		"Rush diagnosis",
		"",
		"Press and hold a key several times.",
		"",
		"Use a different key for each measurement.",
		"For example:",
		"",
		"  hold j",
		"  hold k",
		"  hold j",
		"  hold k",
		"",
		"Release the key between measurements.",
		"",
		"Press <Esc> to finish.",
	})

	for _, key in ipairs(key_set) do
		vim.keymap.set({ "n", "x" }, key, function()
			key_in(key)
			return ""
		end, {
			expr = true,
			silent = true,
		})
	end

	local phase = "measure"

	vim.keymap.set({ "n", "x" }, "<Esc>", function()
		if phase == "measure" then
			phase = "result"

			vim.schedule(function()
				show_result()
			end)

			return ""
		end

		vim.schedule(cleanup)
		return ""
	end, {
		expr = true,
		silent = true,
	})
end

return M
