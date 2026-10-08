local root = assert(os.getenv("KIBI2_REPO_ROOT"))

vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(root .. "/../keyevent.nvim")

KeyEvent = require("keyevent.keyevent")
Config = require("keyevent.config")
Os = require("keyevent.os")
local log = require("keyevent.log")

local M = {}

local test_time = 0

--@class KeyInfo
--@field key string
--@field interval integer
--@field keymap boolean|nil

function M.advance(ms)
	test_time = test_time + ms
end

---	@param sequence KeyInfo[]
function M.run_sequence(sequence)
	print("            (v l s) src type   (t h  r) key (itv h) seq")
	for _, keyinfo in ipairs(sequence) do
		M.advance(keyinfo.interval)
		local keys =
			vim.api.nvim_replace_termcodes(keyinfo.key, true, false, true)
		-- print(keys)
		vim.api.nvim_feedkeys(keys, "xt", false)
		KeyEvent.on_key_test(keyinfo.key)
	end
end

KeyEvent.setup({
	time = function()
		return test_time
	end,
})

CLICK = 900
TAP = 300
HOLD = 500
REPEAT = 150
DELTA = 20

if not Config.threshold.delay then
	Config.threshold.delay = HOLD
	Config.threshold.interval = REPEAT
end

return M
