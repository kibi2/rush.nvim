local common_key = require("common_rush")

---@type KeyInfo[]
local count3 = {
	{ key = "3j", interval = TAP },
	{ key = "j", interval = TAP },
	{ key = "j", interval = HOLD }, -- j wait for the next repeat
	{ key = "j", interval = REPEAT }, -- 3j
	{ key = "j", interval = REPEAT },
	{ key = "k", interval = TAP }, -- 反対方向も共有する
	{ key = "h", interval = CLICK }, -- 他のキーを途中で押しても
	{ key = "k", interval = CLICK }, -- 共有状態に変化はない
	{ key = "k", interval = TAP },
	{ key = "k", interval = HOLD },
	{ key = "k", interval = REPEAT }, -- 6k
	{ key = "k", interval = REPEAT },
	{ key = "1l", interval = CLICK }, -- countを使用すると
	{ key = "j", interval = CLICK }, -- 共有状態はリセットされる
	{ key = "13w", interval = TAP },
	{ key = "w", interval = TAP },
	{ key = "w", interval = HOLD },
	{ key = "w", interval = REPEAT }, -- 13w
	{ key = "b", interval = REPEAT }, -- 13b
	{ key = "<Esc>", interval = HOLD }, -- Escapeでも
	{ key = "w", interval = TAP }, -- 共有状態はリセット
}

common_key.run_sequence(count3)
