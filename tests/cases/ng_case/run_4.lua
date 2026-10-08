local common_rush = require("common_rush")

---@type KeyInfo[]
local tan_click_normal = {
	{ key = "k", interval = CLICK }, -- ta
	{ key = "k", interval = TAP }, -- ta
	{ key = "k", interval = TAP }, -- tan
	{ key = "k", interval = HOLD }, --- repeat 1
	{ key = "k", interval = REPEAT }, -- repeat 2
	{ key = "k", interval = TAP }, -- tan
	{ key = "k", interval = TAP }, -- tan
	{ key = "k", interval = TAP }, -- tan
	{ key = "k", interval = TAP }, -- tan
}

print("\n")
common_rush.run_sequence(tan_click_normal)

---@type KeyInfo[]
local tan_click_ng1 = {
	{ key = "k", interval = CLICK }, -- ta
	{ key = "k", interval = TAP }, -- ta
	{ key = "k", interval = HOLD }, -- tap -> hold : NG!
	{ key = "k", interval = HOLD }, --- repeat 1
	{ key = "k", interval = REPEAT }, -- repeat 2
	{ key = "k", interval = TAP }, -- tan
	{ key = "k", interval = TAP }, -- tan
	{ key = "k", interval = TAP }, -- tan
	{ key = "k", interval = TAP }, -- tan
}

print("\n")
common_rush.run_sequence(tan_click_ng1)
