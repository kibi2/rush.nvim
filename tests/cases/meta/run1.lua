local common_key = require("common_rush")

---@type KeyInfo[]
local count3 = {
	{ key = "j", interval = TAP },
	{ key = "j", interval = HOLD },
	{ key = "j", interval = REPEAT },
	{ key = "<C-j>", interval = REPEAT },
	{ key = "<C-j>", interval = REPEAT },
	{ key = "j", interval = REPEAT },
	{ key = "<C-j>", interval = REPEAT },
	{ key = "j", interval = REPEAT },
	{ key = "<M-j>", interval = REPEAT },
	{ key = "j", interval = REPEAT },
	{ key = "<M-j>", interval = REPEAT },
	{ key = "<M-j>", interval = REPEAT },
	{ key = "j", interval = REPEAT },
	{ key = "<M-j>", interval = REPEAT },
	{ key = "j", interval = REPEAT },
	{ key = "<M-j>", interval = REPEAT },
	{ key = "j", interval = REPEAT },
}

common_key.run_sequence(count3)
