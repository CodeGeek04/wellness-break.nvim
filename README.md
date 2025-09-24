# wellness-break.nvim

A simple Neovim plugin to remind you to take breaks while coding. This plugin automatically triggers wellness breaks after a random number of keystrokes (200-300 by default) to help maintain your health and productivity.

## Features

- 💧 Random wellness break reminders with encouraging messages
- ⏰ Configurable break duration and keystroke thresholds
- 🎯 Automatic keystroke counting
- 🚫 Non-intrusive floating window that doesn't interrupt your workflow
- 🎮 Manual break control commands

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "CodeGeek04/wellness-break.nvim",
  config = function()
    require("wellness-break").setup()
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "CodeGeek04/wellness-break.nvim",
  config = function()
    require("wellness-break").setup()
  end
}
```

## Configuration

Default configuration:

```lua
require("wellness-break").setup({
  min_keystrokes = 200,     -- Minimum keystrokes before break
  max_keystrokes = 300,     -- Maximum keystrokes before break
  break_duration = 20,      -- Break duration in seconds
  messages = {              -- Custom break messages
    "💧 Time to drink some water!",
    "🚶 Take a quick walk around!",
    "👁️ Close your eyes and rest for a moment",
    "🧘 Take 3 deep breaths",
    "💪 Do some quick stretches",
    "🌅 Look away from the screen",
    "🤸 Stand up and move around",
    "☕ Maybe grab a coffee or tea?",
  },
})
```

## Commands

- `:WellnessBreakNow` - Trigger a break immediately
- `:WellnessBreakEnd` - End current break early
- `:WellnessBreakStatus` - Show current keystroke count and status

## How it works

The plugin monitors your keystrokes and triggers a break after a random number of keystrokes (between `min_keystrokes` and `max_keystrokes`). During a break:

1. A floating window appears with a random wellness message
2. The screen is "frozen" to encourage you to actually take the break
3. A countdown timer shows the remaining break time
4. The break automatically ends after the configured duration

## License

MIT License