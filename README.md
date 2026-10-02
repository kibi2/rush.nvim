# rush.nvim

**Control Vim motions with key repeats and holds.**

`rush.nvim` changes the amount of motion based on how you repeat and hold a key.

For example:

```text
For example:

j                 → normal Vim behavior
jj                → normal Vim behavior
jj + hold j       → hold j is replaced with "4j"
7 + hold j        → hold j is replaced with "7j"
```

You can also change the motion amount while holding a key:

```text
hold j            → normal Vim behavior
tap j + hold j    → start with a larger motion

while holding j:
  hold j again    → increase the motion
  tap j + hold j  → decrease the motion
```

The motion can eventually change direction:

j → larger j motions → smaller j motions → -j → larger -j motions

The idea is simple:

> **The meaning of a key can change depending on how it is typed over time.**

## Features

* Time-based key input detection
* Distinguishes clicks, taps, and key repeats
* Accelerates and decelerates repeated motions
* Uses tap sequences to change the motion amount
* Uses Ctrl and Alt as acceleration/deceleration controls on macOS
* Works in normal and visual modes
* Configurable timing thresholds
* Built-in diagnosis command for measuring key repeat timing

## Example

Except for held keys, `rush.nvim` behaves like normal Vim motions.

The following motion keys can be accelerated:

```text
h j k l w b e
```

When you hold one of these keys, `rush.nvim` changes the motion amount according to the preceding taps, the repeat sequence, and, on macOS, the state of the modifier keys.

### Preserve a count

A count is preserved throughout a key repeat sequence.

```text
5 + hold j               → 5j, 5j, 5j, 5j, 5j, ...
```

In other words, each repeated `j` is effectively replaced with `5j`.

### Increase the motion from the beginning

The number of preceding taps determines the initial motion amount.

Acceleration starts one repeat later because `rush.nvim` needs to distinguish taps from holds.

```text
hold j                   → 1j, 1j, 1j, 1j, 1j, ...

tap j + hold j           → 1j, 1j, 2j, 2j, 2j, ...

tap j + tap j + hold j   → 1j, 1j, 1j, 4j, 4j, ...
```

Each additional tap before the hold doubles the motion amount.

### Increase the motion while holding

You can double the motion amount by releasing the key and holding it again.

```text
hold j                   → 1j, 1j, 1j, ...

  + hold j               → 1j, 2j, 2j, ...

  + hold j               → 2j, 4j, 4j, ...
```

Each additional hold doubles the motion amount.

### Decrease the motion while holding

You can also halve the motion amount.

For example:

```text
  + hold j               → 2j, 2j, 2j, 2j, ...

  + tap j + hold j       → 2j, 2j, 1j, 1j, ...

  + tap j + hold j       → 1j, 1j, -1j, -1j, ...
```

When the motion amount reaches one, another decrease reverses the direction.

Further hold sequences then double the motion amount in the opposite direction.

### Use modifier keys to increase or decrease the motion (macOS only)

On macOS, you can change the motion amount while holding a key by tapping a modifier key.

```text
hold j + tap Ctrl        → double the motion amount

hold j + tap Alt         → halve the motion amount
```

Tapping Alt has the same effect as `tap j + hold j`.

> **Note:** On Windows and Ubuntu, pressing a modifier key while a key is repeating may stop the key repeat. macOS does not have this behavior, so modifier-key control is currently supported on macOS only.

You can also change the motion amount with `hold j` or `tap j + hold j`, but `hold j` requires a short wait before the repeat starts.

Using a modifier key avoids this delay, so the motion amount can be changed immediately while the key is repeating.

Modifier keys are also less affected by tap/hold detection errors, since they do not require distinguishing between a tap and a hold.

However, modifier keys may be harder to press depending on the keyboard layout and the position of the motion key.

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

* Neovim 0.10+
* A system with key repeat support

## Limitations

`rush.nvim` relies on Neovim's key mappings and input timing.

The exact timing characteristics depend on:

* your operating system
* your keyboard
* your OS key repeat settings

Use:

```vim
:KeyEvent diagnosis
```

to measure the key repeat timing on your system and determine suitable values.

## License

MIT
