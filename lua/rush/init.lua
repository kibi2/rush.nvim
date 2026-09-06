local M = {}

local count = {}
local last = {}

local function next_motion(motion)
	local now = vim.uv.hrtime()
	local elapsed = (now - last[motion]) / 1e6

	if elapsed > 200 then
		count[motion] = 1
	else
		count[motion] = count[motion] + 1
	end

	last[motion] = now

	if count[motion] == 1 then
		return motion
	end

	return count[motion] .. motion
end

for _, motion in ipairs({ "h", "j", "k", "l" }) do
	vim.keymap.set("n", motion, function()
		return next_motion(motion)
	end, {
		expr = true,
	})
	count[motion] = 0
	last[motion] = 0
end

return M
