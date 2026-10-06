local common_key = require("common_rush")

---@type KeyInfo[]
local count3 = {
	-- Shared counts persist in the opposite direction too.
	{ key = "3j", interval = TAP },
	{ key = "j", interval = TAP },
	{ key = "j", interval = HOLD }, -- j wait for the next repeat
	{ key = "j", interval = REPEAT }, -- 3j
	{ key = "j", interval = REPEAT },
	{ key = "k", interval = TAP }, -- The opposite direction shares the count too.
	{ key = "h", interval = CLICK }, -- Pressing another key in between
	{ key = "k", interval = CLICK }, -- does not change the shared state.
	{ key = "k", interval = TAP },
	{ key = "k", interval = HOLD },
	{ key = "k", interval = REPEAT }, -- 6k
	{ key = "k", interval = REPEAT },
	{ key = "1l", interval = CLICK }, -- Using a count
	{ key = "j", interval = CLICK }, -- resets the shared state.
	{ key = "13w", interval = TAP },
	{ key = "w", interval = TAP },
	{ key = "w", interval = HOLD },
	{ key = "w", interval = REPEAT }, -- 13w
	{ key = "b", interval = REPEAT }, -- 13b
	{ key = "<Esc>", interval = HOLD }, -- Escape also
	{ key = "w", interval = TAP }, -- resets the shared state.
}

common_key.run_sequence(count3)
