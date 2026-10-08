local common_key = require("common_rush")

---@type KeyInfo[]
local count3 = {
	{ key = "j", interval = CLICK },
	{ key = "j", interval = TAP },
	{ key = "j", interval = HOLD }, -- "j" wait for the next repeat
	{ key = "j", interval = REPEAT }, -- "2j"
	{ key = "j", interval = REPEAT },
	{ key = "j", interval = TAP },
	{ key = "j", interval = HOLD }, -- "4j"
	{ key = "j", interval = REPEAT },
	{ key = "j", interval = REPEAT },
	{ key = "k", interval = TAP },
	{ key = "k", interval = HOLD }, -- "2j"
	{ key = "k", interval = REPEAT },
	{ key = "k", interval = REPEAT },
	{ key = "k", interval = TAP },
	{ key = "k", interval = HOLD }, -- "j"
	{ key = "k", interval = REPEAT },
	{ key = "k", interval = REPEAT },
	{ key = "k", interval = TAP },
	{ key = "k", interval = HOLD }, -- "k"
	{ key = "k", interval = REPEAT },
	{ key = "k", interval = REPEAT },
	{ key = "k", interval = TAP },
	{ key = "k", interval = TAP },
	{ key = "k", interval = HOLD }, -- "4k"
	{ key = "k", interval = REPEAT },
	{ key = "k", interval = REPEAT },
	{ key = "j", interval = TAP },
	{ key = "j", interval = HOLD }, -- "2k"
	{ key = "j", interval = REPEAT },
	{ key = "j", interval = REPEAT },
	{ key = "j", interval = TAP },
	{ key = "j", interval = TAP },
	{ key = "j", interval = TAP },
	{ key = "j", interval = HOLD }, -- "2j"
	{ key = "j", interval = REPEAT },
	{ key = "j", interval = REPEAT },
}

common_key.run_sequence(count3)
