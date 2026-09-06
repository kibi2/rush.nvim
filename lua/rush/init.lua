local M = {}

local count = 0

local function next_j()
	count = count + 1

	if count == 1 then
		return "j"
	end

	return count .. "j"
end

vim.keymap.set("n", "j", next_j, {
	expr = true,
})

return M
