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
local prev_key = nil
local prev_time = nil

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
-- diagnosis
--------------------------------------------------

---@param values number[]
---@return number[] small
---@return number[] large
local function split_values(values)
	local sorted = vim.deepcopy(values)
	table.sort(sorted)

	if #sorted < 2 then
		return sorted, {}
	end

	local split_index = 1
	local max_gap = 0

	for i = 1, #sorted - 1 do
		local gap = sorted[i + 1] - sorted[i]

		if gap > max_gap then
			max_gap = gap
			split_index = i
		end
	end

	local small = {}
	local large = {}

	for i, value in ipairs(sorted) do
		if i <= split_index then
			table.insert(small, value)
		else
			table.insert(large, value)
		end
	end

	return small, large
end

---@return table?
local function analyze()
	if #measurements < 2 then
		return nil
	end

	local small, large = split_values(measurements)

	if #small == 0 or #large == 0 then
		return nil
	end

	return {
		small = small,
		large = large,
		rep = small[#small],
		hold1 = large[1],
		hold2 = large[#large],
	}
end

--------------------------------------------------
-- display
--------------------------------------------------

local function show_measurements()
	local lines = {
		"Rush diagnosis",
		"",
		"Press and hold a key several times.",
		"Release the key between each measurement.",
		"",
		"Press <Esc> to finish.",
		"",
		"Measurements:",
	}

	for _, value in ipairs(measurements) do
		table.insert(lines, string.format("  %d ms", value))
	end

	set_lines(lines)
end

local function show_result()
	local result = analyze()

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
		string.format("    min: %d ms", result.small[1]),
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

--------------------------------------------------
-- input
--------------------------------------------------

---@param key string
local function key_in(key)
	local now = vim.loop.hrtime()

	-- 新しい測定の開始
	if prev_key ~= key then
		prev_key = key
		prev_time = now
		return
	end

	-- 同じキーのリピート
	local delta_t = (now - prev_time) / 1e6

	table.insert(measurements, math.floor(delta_t + 0.5))

	prev_time = now

	vim.schedule(show_measurements)
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
		"Release the key between each measurement.",
		"",
		"Press <Esc> to finish.",
	})

	for _, key in ipairs(key_set) do
		vim.keymap.set({ "n", "x" }, key, function()
			key_in(key)
			return key
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
