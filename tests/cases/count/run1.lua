local common_key = require("common_rush")

---@type KeyInfo[]
local count3 = {
	{ key = "3j", interval = TAP },
	{ key = "j", interval = HOLD }, -- "j" wait for the next repeat
	{ key = "j", interval = REPEAT }, -- "3j"
	{ key = "j", interval = REPEAT },
	{ key = "1j", interval = CLICK },
	{ key = "j", interval = HOLD }, -- "j" wait for the next repeat
	{ key = "j", interval = REPEAT },
	{ key = "j", interval = REPEAT },
	{ key = "j", interval = TAP },
	{ key = "5k", interval = CLICK },
	{ key = "k", interval = HOLD }, -- "j" wait for the next repeat
	{ key = "k", interval = REPEAT }, -- "5j"
	{ key = "k", interval = REPEAT },
	{ key = "k", interval = TAP },
	{ key = "k", interval = HOLD },
	{ key = "k", interval = REPEAT }, -- "20j"
	{ key = "k", interval = REPEAT },
	{ key = "6k", interval = TAP },
	{ key = "k", interval = HOLD },
	{ key = "k", interval = REPEAT },
	{ key = "k", interval = REPEAT },
}

common_key.run_sequence(count3)
