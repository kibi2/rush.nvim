local common_key = require("common_rush")

---@type KeyInfo[]
local count3 = {
	{ key = "j", interval = CLICK },
	{ key = "j", interval = HOLD }, -- "j" wait for the next repeat
	{ key = "j", interval = REPEAT }, -- "1j"
	{ key = "j", interval = REPEAT },
	{ key = "j", interval = TAP },
	{ key = "j", interval = HOLD }, -- "2j"
	{ key = "j", interval = REPEAT },
	{ key = "j", interval = REPEAT },
	{ key = "j", interval = TAP },
	{ key = "j", interval = TAP },
	{ key = "j", interval = HOLD }, -- "8j"
	{ key = "j", interval = REPEAT },
	{ key = "j", interval = REPEAT },
	{ key = "j", interval = TAP },
	{ key = "j", interval = TAP },
	{ key = "j", interval = TAP },
	{ key = "j", interval = HOLD }, -- "64j"
	{ key = "j", interval = REPEAT },
	{ key = "j", interval = REPEAT },
	{ key = "j", interval = TAP },
	{ key = "j", interval = TAP },
	{ key = "j", interval = TAP },
	{ key = "j", interval = TAP }, -- reset
	{ key = "j", interval = HOLD }, -- "1j"
	{ key = "j", interval = REPEAT },
	{ key = "j", interval = REPEAT },
}

common_key.run_sequence(count3)
