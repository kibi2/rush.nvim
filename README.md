# rush.nvim

**Time-based key mappings for Neovim.**

`rush.nvim` changes the behavior of repeated motion keys according to the timing of your key presses.

It lets you use a normal key for a normal motion, tap it repeatedly for a different motion, and hold it to repeat that motion at higher speed.

For example:

```text
j               → j
jj              → j
jj + hold j     → 10j repeat
8  + hold j     →  8j repeat
```

The idea is simple:

> **The meaning of a key can change depending on how it is typed over time.**

## Features

* Time-based key input detection
* Distinguishes taps, hold start, and key repeats
* Accelerates repeated motions
* Works with normal and visual modes
* Configurable timing thresholds
* Configurable rush counts
* Built-in diagnosis command for measuring your keyboard's actual timing

## How it works

`rush.nvim` watches a small set of motion keys and classifies consecutive inputs by their timing.

For example:

```text
j
j
j  ───────────── hold
    ↑
    hold start
        ↓
    key repeats
```

A typical sequence might become:

```text
j           → j
jj          → j
jj + hold   → 10j repeat
```

The exact behavior depends on your configured timing thresholds and rush counts.

Different keys are treated independently. Typing another key breaks the current sequence.

## Installation

Using [lazy.nvim]:

```lua
{
	"kibi2/rush.nvim",
	opts = {},
}
```

Or:

```lua
{
	"kibi2/rush.nvim",
	config = function()
		require("rush").setup()
	end,
}
```

## Configuration

The default configuration is:

```lua
require("rush").setup({
	interval = {
		rep = 95,
		hold1 = 490,
		hold2 = 510,
		tap = 1000,
	},

	rush_count = {
		"vim",
		5,
		10,
		20,
	},
})
```

### `interval`

These values define how key intervals are interpreted.

```lua
interval = {
	rep = 95,
	hold1 = 490,
	hold2 = 510,
	tap = 1000,
}
```

All values are in milliseconds.

| Interval         | Event       |
| ---------------- | ----------- |
| `<= rep`         | hold repeat |
| `rep .. hold1`   | tap         |
| `hold1 .. hold2` | hold start  |
| `hold2 .. tap`   | tap         |
| `> tap`          | click       |

A different keyboard, operating system, or key-repeat setting may require different values.

For this reason, `rush.nvim` provides a diagnosis command.

## Diagnosis

Run:

```vim
:Rush diagnosis
```

A floating window shows the measured timing while you use your normal buffer.

For example:

```text
===== Rush diagnosis =====

Press and hold a key several times.

Use a different key for each measurement.
For example:

  hold j
  hold k
  hold j
  hold k

----------------------------------------
Detected intervals:

        count   min(ms)   max(ms)
hold        4       490       503
repeat     32        82        95

Suggested configuration:

  rep   = 98,
  hold1 = 487,
  hold2 = 506,

----------------------------------------

Press <Esc> to close.
```

The suggested values can be copied directly into your configuration.

During diagnosis, the original buffer remains active, so the measurements are made while using your normal Neovim environment.

Press `<Esc>` to finish.

## `rush_count`

`rush_count` controls the count used for each level of repeated motion.

The default is:

```lua
rush_count = {
	"vim",
	5,
	10,
	20,
}
```

`"vim"` uses the count supplied by Vim.

`"none"` disables the count for that level.

For example:

```lua
rush_count = {
	"none",
	5,
	10,
	20,
}
```

The number of entries determines how many rush levels are available.

## Example

With:

```lua
rush_count = {
	"vim",
	5,
	10,
	20,
}
```

a possible interaction is:

```text
j               → j
jj              → j
jj + hold j     → 10j repeat
8 + hold j      →  8j repeat
```

The same mechanism can be used for other motion keys such as:

```text
h j k l
w b e
W B E
```

The default key set is:

```lua
{
	"h",
	"j",
	"k",
	"l",
	"w",
	"b",
	"e",
	"W",
	"B",
	"E",
}
```

## Why?

Vim's motions work extremely well for navigating code and text in a terminal.

But when writing long documents on a large screen, I often find them less convenient.

When working on Markdown documents or manuscripts, I frequently want to move the cursor to a completely different part of the screen. Vim has excellent motion commands for this, but they are not always enough for these larger jumps.

As a result, I often end up reaching for the mouse and clicking where I want to go.

`rush.nvim` started from a simple idea:

> **What if I could make these larger movements quickly, without taking my hands off the keyboard?**

Instead of reaching for the mouse, I can use the distance I already have in mind and then hold a motion key:

```text
8 + hold j  →  8j repeat
```

Or, without explicitly entering a count:

```text
jj + hold j → 10j repeat
```

`rush.nvim` explores using the **time axis of key input** as another dimension of Vim's key mappings.

The goal is not to replace Vim's motions, but to make moving around large documents feel more natural when using only the keyboard.

## Requirements

* Neovim 0.10+
* A keyboard with configurable key repeat behavior

## Limitations

`rush.nvim` relies on Neovim's key mapping and input timing.

The exact timing characteristics depend on:

* operating system
* keyboard
* keyboard repeat settings
* terminal
* Neovim input processing

Use `:Rush diagnosis` to determine suitable values for your environment.

## Status

`rush.nvim` is experimental.

The basic implementation is intentionally small. The goal is to explore whether time-based key mappings are useful in everyday Neovim use.

If the idea turns out to be useful, additional patterns may be added in the future.

## License

MIT
