local log = require("rush/log")

local M = {}

local state = "init"
local rep_key = nil
local rep_command = nil
local rep_count = 0

-- ユーザー設定:
-- { 回数, rush倍率 }
--
-- 例:
-- { 3, 2 } = 3回分をrush=2で移動
-- { 3, 4 } = 次の3回分をrush=4で移動
-- { 3, 8 } = 次の3回分をrush=8で移動
local default_rush_steps = {
	{ 3, 2 },
	{ 3, 4 },
	{ 3, 8 },
}

local rush_levels = {}

local function remake_rush_table(rush_steps)
	local result = {}
	local count = 0
	local rush = 1

	for _, step in ipairs(rush_steps) do
		count = count + step[1]

		table.insert(result, {
			count = count,
			rush = rush,
		})

		rush = step[2]
	end

	table.insert(result, {
		count = math.huge,
		rush = rush,
	})

	return result
end

local function rush(count)
	for _, v in ipairs(rush_levels) do
		if count <= v.count then
			return v.rush
		end
	end

	return 1
end
local function key_state(typed, is_onkey)
	local old_state = state
	if state == "init" then
		if typed == "g" then
			state = "g"
		else
			state = "repeat"
			rep_key = typed
			rep_command = typed
			rep_count = 2
		end
	elseif state == "g" then
		if typed == "j" or typed == "k" then
			state = "repeat"
			rep_key = typed
			rep_command = "g" .. typed
			rep_count = 2
		else
			state = "init"
		end
	elseif state == "repeat" then
		if typed == rep_key then
			rep_count = rep_count + 1
		else
			state = "init"
		end
	end
	log.probe(
		"%s (%s) %s -> %s %s [%d %s]",
		is_onkey and "on_key" or "keymap",
		vim.inspect(typed),
		old_state,
		state,
		rep_key,
		rep_count,
		rep_command
	)
end

local function new_motion(motion, n_rep)
	log.probe(
		"%s = %s, %s %s [%d %s]",
		n_rep and "new_motion" or "through",
		motion,
		state,
		rep_key,
		rep_count,
		rep_command
	)
	-- return motion
	return "2" .. rep_command
end

local keymap_key = nil
local function key_flow(typed, is_onkey)
	if is_onkey and keymap_key == typed then
		keymap_key = nil
		return
	end
	key_state(typed, is_onkey)
end

local last_key = nil
local last_count = nil

local function on_key(key, typed)
	if #typed == 0 then
		-- log.probe("on_key (%s %s)", vim.inspect(key), vim.inspect(typed))
		return
	end
	-- key_flow(typed, true)
	last_key = typed
end

function M.setup(opts)
	opts = opts or {}
	local rush_steps = opts.rush_steps or default_rush_steps
	rush_levels = remake_rush_table(rush_steps)
end

vim.on_key(on_key)

for _, motion in ipairs({ "h", "j", "k", "l" }) do
	vim.keymap.set("n", motion, function()
		if motion == last_key then
			log.probe("new motion " .. last_count .. motion)
			return last_count .. motion
		else
			last_count = vim.v.count1
			log.probe(last_key)
			log.probe(last_count)
			return motion
		end
	end, {
		expr = true,
	})
end

for _, motion in ipairs({}) do
	vim.keymap.set("n", motion, function()
		log.probe("NG" .. motion)
		keymap_key = motion
		key_flow(motion)
		if true then
			return motion
		end
		if state ~= "repeat" or rep_key ~= motion then
			return new_motion(motion)
		end
		local n_rep = rush(rep_count)
		if n_rep == 1 then
			return new_motion(rep_command, n_rep)
		end
		return new_motion(n_rep .. rep_command, n_rep)
	end, {
		expr = true,
	})
end

M.setup()

return M
