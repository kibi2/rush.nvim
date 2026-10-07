local common_rush = require("common_rush")

---@type KeyInfo[]
local tan_click_normal = {
	{ key = "j", interval = CLICK }, -- tan
	{ key = "j", interval = HOLD }, --- repeat 1
	{ key = "j", interval = REPEAT }, -- repeat 2
	{ key = "j", interval = TAP }, -- tan
	{ key = "j", interval = HOLD }, --- repeat 1
	{ key = "j", interval = REPEAT }, -- repeat 2
	{ key = "j", interval = REPEAT }, -- repeat 3
	{ key = "j", interval = REPEAT }, -- repeat 3
	{ key = "j", interval = TAP }, -- tan
	{ key = "j", interval = HOLD }, --- repeat 1
	{ key = "j", interval = REPEAT }, -- repeat 2
	{ key = "j", interval = REPEAT }, -- repeat 3
}

print("\n")
common_rush.run_sequence(tan_click_normal)

---@type KeyInfo[]
local tan_click_ng1 = {
	{ key = "j", interval = CLICK }, -- tan
	{ key = "j", interval = HOLD }, --- repeat 1
	{ key = "j", interval = REPEAT }, -- repeat 2
	{ key = "j", interval = REPEAT }, -- NG!
	{ key = "j", interval = HOLD }, --- repeat 1
	{ key = "j", interval = REPEAT }, -- repeat 2
	{ key = "j", interval = REPEAT }, -- repeat 3
	{ key = "j", interval = REPEAT }, -- repeat 3
	{ key = "j", interval = TAP }, -- tan
	{ key = "j", interval = HOLD }, --- repeat 1
	{ key = "j", interval = REPEAT }, -- repeat 2
	{ key = "j", interval = REPEAT }, -- repeat 3
}

print("\n")
common_rush.run_sequence(tan_click_ng1)
