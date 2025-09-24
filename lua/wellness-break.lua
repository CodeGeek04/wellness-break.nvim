-- wellness-break.nvim
-- A simple plugin to remind you to take breaks while coding

local M = {}

-- Default configuration
local config = {
  min_keystrokes = 200,
  max_keystrokes = 300,
  break_duration = 20, -- seconds
  keystroke_mode = "all", -- "all" or "insert_only"
  messages = {
    "💧 Time to drink some water!",
    "🚶 Take a quick walk around!",
    "👁️ Close your eyes and rest for a moment",
    "🧘 Take 3 deep breaths",
    "💪 Do some quick stretches",
    "🌅 Look away from the screen",
    "🤸 Stand up and move around",
    "☕ Maybe grab a coffee or tea?",
  },
}

-- Plugin state
local state = {
  keystroke_count = 0,
  target_keystrokes = 0,
  is_break_active = false,
  break_timer = nil,
  original_eventignore = "",
  break_buf = nil,
  break_win = nil,
}

-- Generate random target keystroke count
local function generate_target()
  math.randomseed(os.time())
  return math.random(config.min_keystrokes, config.max_keystrokes)
end

-- Get random break message
local function get_random_message()
  math.randomseed(os.time() + state.keystroke_count)
  return config.messages[math.random(#config.messages)]
end

-- Create break window and show message
local function show_break_screen()
  state.is_break_active = true

  -- Save current eventignore setting
  state.original_eventignore = vim.o.eventignore

  -- Ignore all events to "freeze" the screen
  vim.o.eventignore = "all"

  -- Create a new buffer for the break message
  state.break_buf = vim.api.nvim_create_buf(false, true)

  -- Get screen dimensions
  local width = vim.o.columns
  local height = vim.o.lines

  -- Calculate window size and position (centered)
  local win_width = math.min(60, width - 4)
  local win_height = 8
  local row = math.floor((height - win_height) / 2)
  local col = math.floor((width - win_width) / 2)

  -- Create floating window
  state.break_win = vim.api.nvim_open_win(state.break_buf, true, {
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Wellness Break ",
    title_pos = "center",
  })

  -- Set window highlight
  vim.api.nvim_set_option_value("winhl", "Normal:WarningMsg,FloatBorder:WarningMsg", { win = state.break_win })

  -- Prepare break message
  local message = get_random_message()
  local lines = {
    "",
    "    " .. message,
    "",
    "    ⏰ Please wait " .. config.break_duration .. " seconds...",
    "",
    "    (This window will close automatically)",
    "",
  }

  -- Set buffer content
  vim.api.nvim_buf_set_lines(state.break_buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = state.break_buf })
  vim.api.nvim_set_option_value("readonly", true, { buf = state.break_buf })

  -- Start countdown timer
  local countdown = config.break_duration
  state.break_timer = vim.uv.new_timer()

  state.break_timer:start(
    1000,
    1000,
    vim.schedule_wrap(function()
      countdown = countdown - 1

      if countdown > 0 then
        -- Update countdown display
        local updated_lines = {
          "",
          "    " .. message,
          "",
          "    ⏰ Please wait " .. countdown .. " seconds...",
          "",
          "    (This window will close automatically)",
          "",
        }

        if vim.api.nvim_buf_is_valid(state.break_buf) then
          vim.api.nvim_set_option_value("modifiable", true, { buf = state.break_buf })
          vim.api.nvim_buf_set_lines(state.break_buf, 0, -1, false, updated_lines)
          vim.api.nvim_set_option_value("modifiable", false, { buf = state.break_buf })
        end
      else
        -- Break time is over
        End_break_screen()
      end
    end)
  )
end

-- End break screen and restore normal functionality
function End_break_screen()
  state.is_break_active = false

  -- Stop and close timer
  if state.break_timer then
    state.break_timer:stop()
    state.break_timer:close()
    state.break_timer = nil
  end

  -- Close break window and buffer
  if state.break_win and vim.api.nvim_win_is_valid(state.break_win) then
    vim.api.nvim_win_close(state.break_win, true)
  end
  if state.break_buf and vim.api.nvim_buf_is_valid(state.break_buf) then
    vim.api.nvim_buf_delete(state.break_buf, { force = true })
  end

  state.break_win = nil
  state.break_buf = nil

  -- Restore original eventignore setting
  vim.o.eventignore = state.original_eventignore

  -- Reset keystroke counter and generate new target
  state.keystroke_count = 0
  state.target_keystrokes = generate_target()

  print("Wellness break complete! Next break in " .. state.target_keystrokes .. " keystrokes.")
end

-- Keystroke counter function
local function count_keystroke()
  if state.is_break_active then
    return
  end

  state.keystroke_count = state.keystroke_count + 1

  if state.keystroke_count >= state.target_keystrokes then
    show_break_screen()
  end
end

-- Setup function
function M.setup(user_config)
  -- Merge user config with defaults
  if user_config then
    config = vim.tbl_deep_extend("force", config, user_config)
  end

  -- Initialize target
  state.target_keystrokes = generate_target()

  -- Set up autocommand to count keystrokes
  vim.api.nvim_create_augroup("WellnessBreak", { clear = true })

  -- Monitor keystrokes using KeyPress event
  vim.on_key(function(key, typed)
    -- Check if we should count keystrokes based on the mode setting
    local should_count = false

    if config.keystroke_mode == "all" then
      should_count = true
    elseif config.keystroke_mode == "insert_only" then
      local mode = vim.api.nvim_get_mode().mode
      should_count = (mode == "i" or mode == "R" or mode == "Rv")
    end

    -- Only count actual keystrokes, not special keys like <Esc>, <CR>, etc
    -- Count printable characters and common editing keys
    if
      not state.is_break_active
      and should_count
      and (
        (typed and typed ~= "") -- Any typed character
        or key:match("^[%w%p%s]$") -- Alphanumeric, punctuation, or space
        or key == vim.api.nvim_replace_termcodes("<BS>", true, false, true) -- Backspace
        or key == vim.api.nvim_replace_termcodes("<Del>", true, false, true) -- Delete
        or key == vim.api.nvim_replace_termcodes("<Tab>", true, false, true) -- Tab
        or key == vim.api.nvim_replace_termcodes("<CR>", true, false, true) -- Enter
      )
    then
      count_keystroke()
    end
  end, vim.api.nvim_create_namespace("WellnessBreakKeyMonitor"))

  -- Commands for manual control
  vim.api.nvim_create_user_command("WellnessBreakNow", show_break_screen, {})
  vim.api.nvim_create_user_command("WellnessBreakEnd", End_break_screen, {})
  vim.api.nvim_create_user_command("WellnessBreakStatus", function()
    local remaining = state.target_keystrokes - state.keystroke_count
    print("Wellness Break Status:")
    print("  Keystrokes: " .. state.keystroke_count .. "/" .. state.target_keystrokes)
    print("  Remaining: " .. remaining)
    print("  Break active: " .. tostring(state.is_break_active))
  end, {})

  print("Wellness Break plugin loaded! Next break in " .. state.target_keystrokes .. " keystrokes.")
end

return M
