local common_key = require("common_rush")

---@type KeyInfo[]
local count3 = {
	{ key = "j", interval = CLICK },
	{ key = "j", interval = HOLD }, -- "j" wait for the next repeat
	{ key = "j", interval = REPEAT }, -- "1j"
	{ key = "j", interval = REPEAT },
	{ key = "k", interval = CLICK },
	{ key = "k", interval = TAP },
	{ key = "k", interval = HOLD }, -- "k" wait for the next repeat
	{ key = "k", interval = REPEAT }, -- "2k"
	{ key = "k", interval = REPEAT },
	{ key = "h", interval = CLICK },
	{ key = "h", interval = TAP },
	{ key = "h", interval = TAP },
	{ key = "h", interval = HOLD }, -- "h" wait for the next repeat
	{ key = "h", interval = REPEAT }, -- "4h"
	{ key = "h", interval = REPEAT },
	{ key = "h", interval = TAP },
	{ key = "h", interval = TAP },
	{ key = "h", interval = TAP },
	{ key = "l", interval = TAP },
	{ key = "l", interval = TAP },
	{ key = "l", interval = TAP },
	{ key = "l", interval = TAP }, -- reset
	{ key = "l", interval = HOLD }, -- "l" wait for the next repeat
	{ key = "l", interval = REPEAT }, -- "1l" reset
	{ key = "l", interval = REPEAT },
	{ key = "w", interval = CLICK },
	{ key = "w", interval = TAP },
	{ key = "w", interval = TAP },
	{ key = "w", interval = HOLD }, -- "w" wait for the next repeat
	{ key = "w", interval = REPEAT }, -- "4w"
	{ key = "w", interval = REPEAT },
	{ key = "b", interval = CLICK },
	{ key = "b", interval = CLICK },
	{ key = "b", interval = TAP },
	{ key = "b", interval = TAP },
	{ key = "b", interval = TAP }, -- reset
	{ key = "b", interval = TAP },
	{ key = "b", interval = TAP },
	{ key = "b", interval = HOLD }, -- "b" wait for the next repeat
	{ key = "b", interval = REPEAT }, -- "1b"
	{ key = "b", interval = REPEAT },
	{ key = "b", interval = TAP },
}

common_key.run_sequence(count3)
