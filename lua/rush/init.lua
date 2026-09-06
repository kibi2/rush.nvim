local M = {}

local count = 0
local last_j = 0

local function next_j()
	local now = vim.uv.hrtime()
	local elapsed = (now - last_j) / 1e6

	if elapsed > 200 then
		count = 1
	else
		count = count + 1
	end

	last_j = now

	if count == 1 then
		return "j"
	end

	return count .. "j"
end

vim.keymap.set("n", "j", next_j, {
	expr = true,
})

return M
