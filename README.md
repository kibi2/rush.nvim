# rush.nvim

**Time-based key mappings for Neovim.**

`rush.nvim` changes the behavior of repeated motion keys according to the timing of your key presses.

It lets you use a normal key for a normal motion, tap it repeatedly for a different motion, and hold it to repeat that motion at higher speed.

For example:

```text
j               → j
jj              → j
jj + hold j     → 4j repeat
7  + hold j     → 7j repeat
```

The idea is simple:

> **The meaning of a key can change depending on how it is typed over time.**

## Features

* Time-based key input detection
* Distinguishes taps, hold start, and key repeats
* Accelerates repeated motion
* key repeat前後のtapを組み合わせることで加速、減速できます
* key repeat中にCtrl, Alt キーをタップすると加速、減速できます(Mac 限定)
* Works with normal and visual modes
* Configurable timing thresholds
* Built-in diagnosis command for measuring key repeat timing

## How it works

keyevent.nvimを利用して一連のkeyeventの組み合わせに応じてカーソル移動量を変化させます。
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
jj + hold   → 4j repeat
```

The exact behavior depends on your configured timing thresholds and rush counts.

Different keys are treated independently. Typing another key starts a new sequence

## Installation

### lazy.nvim

```lua
{
  "kibi2/rush.nvim",
  dependencies = {
    { 'kibi2/keyevent.nvim' },
  },
  config = function()
    require('rush').setup {}
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

keyevent.nvim の設定方法については[[keyevent.nvim]](https://github.com/kibi2/keyevent.nvim)を参照してください

## Example

key hold 以外は普通のvimコマンドとして使えます。
h, j, k, l, m, w, e, b をholdするとrush.nvimがtap回数、hold回数、metaキーの状態(mac限定)に応じて移動量をかえます。

### countを持続する

5 hold j とすると5行ずつ下に移動します。つまりhold j でrepeat する"j"はすべて"5j"に置き換わります

### 最初から移動量を増やす

tap j hold j で2行づつ移動します。
tap j tap j hold j で4行づつ移動します。
hold j の前のtap jの回数に応じて移動量が倍、倍、になります。

### 途中で移動量を増やす

hold j で1行ずつ移動しますが、さらに続けてhold jで移動量が2倍になります。hold jを繰り返すたびに移動量が倍になります。

### 途中で移動量を減らす

hold j で2行ずつ移動している時にtap jhold jで移動量が半分になります。hold jを繰り返すたびに移動量が半分になります。
1行ずつ移動している時にtap jhold jで移動方向が逆向きになります。hold jを繰り返すたびに逆向きの移動量が倍になります。

### メタキーを使って途中で移動量を増減する（Mac 限定）

hold j で移動している時にCtrlをタップするごとに移動量が倍に増えます。
hold j で移動している時にAltをタップするごとに移動量が半分に減ります。tap jhold jと同じ動作をします。

## Why?

Vim's motions work extremely well for navigating code and text in a terminal.

But when writing long documents on a large screen, I often find them less convenient.

When working on Markdown documents or manuscripts, I frequently want to move the cursor to a completely different part of the screen. Vim has excellent motion commands for this, but they are not always enough for these larger jumps.

As a result, I often end up reaching for the mouse and clicking where I want to go.

`rush.nvim` started from a simple idea:

> **What if I could make these larger movements quickly, without taking my hands off the keyboard?**

Instead of reaching for the mouse, I can use the distance I already have in mind and then hold a motion key:

```text
7 + hold j  →  7j repeat
```

Or, without explicitly entering a count:

```text
jj + hold j → 4j repeat
```

`rush.nvim` explores using the **time axis of key input** as another dimension of Vim's key mappings.

The goal is not to replace Vim's motions, but to make moving around large documents feel more natural when using only the keyboard.

## Requirements

* Neovim 0.10+
* A system with key repeat support

## Limitations

`rush.nvim` relies on Neovim's key mapping and input timing.

The exact timing characteristics depend on your:

* operating system
* keyboard repeat settings

Use `:KeyEvent diagnosis` to determine suitable values for your environment.

## License

MIT

