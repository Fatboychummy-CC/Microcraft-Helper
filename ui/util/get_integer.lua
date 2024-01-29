local PrimeUI = require "PrimeUI_cherrypicked"

--- Get an integer value from the user (or nil if the user cancelled).
---@param menu_subtitle string The subtitle of the menu.
---@param default_value number? The default value to show in the input box.
---@param min number? The minimum value the user can enter.
---@param max number? The maximum value the user can enter.
---@return number? value The value the user entered, or nil if the user cancelled.
return function(menu_subtitle, default_value, min, max)
  local w = term.getSize()
  local current_n = tonumber(default_value) or 0
  min = min or -math.huge
  max = max or math.huge

  -- Set up the page.
  PrimeUI.clear()
  require "ui.title" (menu_subtitle)

  -- Draw a box around the input box.
  PrimeUI.borderBox(term.current(), 4, 7, w - 6, 1)

  -- Add a textbox below the input box
  PrimeUI.textBox(term.current(), 4, 9, w - 6, 3,
    "Press END to cancel, use arrow keys to increase or decrease the value.")

  -- Add the number input box.
  local redraw_textbox = PrimeUI.textBox(term.current(), 4, 7, w - 6, 1, tostring(current_n))

  PrimeUI.keyAction(keys.up, function()
    current_n = current_n + 1

    if current_n > max then
      current_n = max
    end

    redraw_textbox(tostring(current_n))
  end)
  PrimeUI.keyAction(keys.down, function()
    current_n = current_n - 1

    if current_n < min then
      current_n = min
    end

    redraw_textbox(tostring(current_n))
  end)
  PrimeUI.keyAction(keys.pageUp, function()
    current_n = current_n + 1000

    if current_n > max then
      current_n = max
    end

    redraw_textbox(tostring(current_n))
  end)
  PrimeUI.keyAction(keys.pageDown, function()
    current_n = current_n - 1000

    if current_n < min then
      current_n = min
    end

    redraw_textbox(tostring(current_n))
  end)

  PrimeUI.keyAction(keys["end"], "cancel")
  PrimeUI.keyAction(keys.enter, "done")

  local input, action = PrimeUI.run()

  if input == "keyAction" and action == "done" then
    return current_n
  end
end
