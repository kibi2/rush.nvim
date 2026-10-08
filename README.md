# rush.nvim

[![CI](https://github.com/kibi2/rush.nvim/actions/workflows/ci.yml/badge.svg)](https://github.com/kibi2/rush.nvim/actions)
[![codecov](https://codecov.io/gh/kibi2/rush.nvim/branch/main/graph/badge.svg)](https://codecov.io/gh/kibi2/rush.nvim)
![GitHub release](https://img.shields.io/github/v/release/kibi2/rush.nvim)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Neovim](https://img.shields.io/badge/Neovim-0.10+-57A143?logo=neovim)

**Control Vim motions with key repeats and holds.**

`rush.nvim` changes the amount of motion based on how you repeat and hold a key.

For example:

```text
j                 → normal Vim behavior
jj                → normal Vim behavior
j + hold j        → hold j is replaced with "2j"
jj + hold j       → hold j is replaced with "4j"
7 + hold j        → hold j is replaced with "7j"
5 + j + hold j    → share count 5 between j and k
```

You can also change the motion amount while holding a key:

```text
hold j            → normal Vim behavior
tap j + hold j    → start with a larger motion

while holding j:
  hold j again    → increase the motion
  hold k          → decrease the motion
```

The motion can eventually change direction:

```text
j → larger j motions → smaller j motions → reverse direction → larger reverse motions
```

The idea is simple:

> **The meaning of a key can change depending on how it is typed over time.**

## Features

- Time-based key input detection
- Distinguishes clicks, taps, and key repeats
- Accelerates and decelerates repeated motions
- Uses tap sequences to change the motion amount
- Uses Ctrl and Alt as acceleration/deceleration controls on macOS
- Shares motion amounts between `j`/`k` or `h`/`l`
- Works in normal and visual modes
- Configurable timing thresholds
- Built-in diagnosis command for measuring key repeat timing

## Example

Except for held keys, `rush.nvim` behaves like normal Vim motions.

The following motion keys can be accelerated:

```text
h j k l w b
```

When you hold one of these keys, `rush.nvim` changes the motion amount according to the preceding taps, the repeat sequence, and, on macOS, the state of the modifier keys.

### Preserve a count

A count is preserved throughout a key repeat sequence.

```text
5 + hold j               → 5j repeat
```

In other words, each repeated `j` is effectively replaced with `5j`.

### Increase the motion from the beginning

The number of preceding taps determines the motion amount for subsequent repeats.

Acceleration starts one repeat later because `rush.nvim` needs to distinguish taps from holds.

```text
hold j                   → 1j repeat

tap j + hold j           → 2j repeat

tap j + tap j + hold j   → 4j repeat
```

The initial `j` of a sequence is always executed as `1j`; the increased motion applies to subsequent repeats.

Each additional tap before the hold doubles the motion amount.

### Increase the motion while holding

You can double the motion amount by releasing the key and holding it again.

```text
hold j                   → 1j repeat

+ hold j                 → 2j repeat

+ hold j                 → 4j repeat
```

Each additional hold doubles the motion amount.

### Decrease the motion while holding

You can also halve the motion amount.

For example:

```text
+ hold j                 → 2j repeat

+ hold k                 → 1j repeat

+ hold k                 → 1k repeat
```

When the motion amount reaches one, another decrease reverses the direction.

Further hold sequences then double the motion amount in the opposite direction.

### Use modifier keys to increase or decrease the motion (macOS only)

On macOS, you can change the motion amount while holding a key by tapping a modifier key.

```text
hold j + tap Ctrl        → double the motion amount

hold j + tap Alt         → halve the motion amount
```

Tapping Ctrl provides a convenient way to accelerate the motion without releasing the motion key.

Tapping Alt provides a convenient way to decelerate the motion without changing the direction.

> **Note:** On Windows and Ubuntu, pressing a modifier key while a key is repeating may stop the key repeat. macOS does not have this behavior, so modifier-key control is currently supported on macOS only.

You can also change the motion amount with `hold j` or `hold k`. For example, while holding `j`, holding `k` decreases the motion amount and eventually reverses the direction.

Modifier keys provide an alternative way to change the motion amount while a key is repeating. Unlike `hold j` or `hold k`, they do not require releasing and holding another motion key.

Modifier keys are also less affected by tap/hold detection errors, since they do not require distinguishing between a tap and a hold.

However, modifier keys may be harder to press depending on the keyboard layout and the position of the motion key.

Choose whichever method feels more comfortable for your keyboard and workflow.

### Share the motion

A motion amount can be shared between `j` and `k`.

For example:

```text
5j + hold j             → 5j repeat

k, k, j, k              → 5k, 5k, 5j, 5k

1k, k, j, k             → 1k, k, j, k
                           (shared count is reset)
```

The shared count can also be cleared by pressing `Esc`.

Motion amounts can be shared between the following pairs:

```text
j / k
h / l
w / b
```

Using another count with a motion key, such as `3h`, exits shared mode.

Using a count with another Vim command, such as `2dd`, does not exit shared mode.

## How it works

`rush.nvim` uses [`keyevent.nvim`](https://github.com/kibi2/keyevent.nvim) to detect sequences of key events and their timing.

The same motion key can therefore have different meanings depending on how it is typed:

```text
j
j
j ───────────── hold
                ↓
            key repeats
```

The exact behavior depends on the timing thresholds configured for your environment.

Different keys are treated independently. Typing another key starts a new sequence.

## Installation

### lazy.nvim

```lua
{
  "kibi2/rush.nvim",
  dependencies = {
    { "kibi2/keyevent.nvim" },
  },
  config = function()
    require("rush").setup({})
    require("keyevent").setup({
      interval = {
        delta = 20,
        tap = 500,
      },
    })
  end,
}
```

## Configuration

`rush.nvim` uses `keyevent.nvim` for key-event detection.

If tap/hold detection is not working reliably, increase the `delta` value.

If you want slower key presses to still be detected as taps rather than clicks, increase the `tap` value.

Both values are specified in milliseconds.

See the [`keyevent.nvim` README](https://github.com/kibi2/keyevent.nvim) for configuration options.

## Why?

Vim's motions work extremely well for navigating code and text.

However, when working on long Markdown documents or manuscripts on a large screen, I often want to move the cursor much farther than a normal motion provides.

I sometimes end up reaching for the mouse and clicking where I want to go.

`rush.nvim` started from a simple idea:

> **What if I could make these larger movements quickly, without taking my hands off the keyboard?**

Instead of reaching for the mouse, I can use the distance I already have in mind and then hold a motion key:

```text
7 + hold j        → 7j repeat
```

Or, without explicitly entering a count:

```text
jj + hold j       → hold j is replaced with "4j"
```

`rush.nvim` explores the **time axis of key input** as another dimension of Vim's key mappings.

The goal is not to replace Vim's motions, but to make moving around large documents feel more natural when using only the keyboard.

## Requirements

- Neovim 0.10+
- A system with key repeat support

## Limitations

`rush.nvim` relies on Neovim's key mappings and input timing.

The exact timing characteristics depend on:

- your operating system
- your keyboard
- your OS key repeat settings

Use:

```vim
:KeyEvent diagnosis
```

to measure the key repeat timing on your system and determine suitable values.

## License

MIT