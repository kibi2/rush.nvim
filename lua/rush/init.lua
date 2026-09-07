local M = {}

local state = "init"
local rep_key = nil
local rep_command = nil
local rep_count = 0

-- TODO: count と連打間隔から加速量を決める
local function rush(count)
	if count == 1 then
		return 1
	elseif count == 2 then
		return 2
	elseif count == 3 then
		return 4
	elseif count == 4 then
		return 8
	end
	return 8
end

local function on_key(key, typed)
	if #typed == 0 then
		return
	end
	-- print("on_key", tostring(key), vim.inspect(typed))
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
end

vim.on_key(on_key)

for _, motion in ipairs({ "h", "j", "k", "l" }) do
	vim.keymap.set("n", motion, function()
		-- print("keymap" .. motion)
		if state ~= "repeat" or rep_key ~= motion then
			return motion
		end
		local n_rep = rush(rep_count)
		print(rep_count)
		if n_rep == 1 then
			return rep_command
		end
		return n_rep .. rep_command
	end, {
		expr = true,
	})
end

return M
