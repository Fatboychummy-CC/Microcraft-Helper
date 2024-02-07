local PrimeUI = require "PrimeUI_cherrypicked"

local util = require "util"

--- Display a message to the user.
---@param subtitle string The subtitle of the menu.
---@param message string The message to display.
---@param ... integer? The keys possible to use to confirm the selection. Defaults to just keys.enter.
---@return integer key The key that was pressed to confirm the selection.
return function(subtitle, message, ...)
  local w, h = term.getSize()
  local keys_possible = table.pack(...)

  -- Set up the page.
  PrimeUI.clear()
  local scrollbox = PrimeUI.scrollBox(term.current(), 3, 7, w - 4, h - 10, util.get_line_count(message, w - 5) + 3, true, true)
  require "ui.title" (subtitle, colors.green, colors.green)

  PrimeUI.textBox(scrollbox, 1, 1, w - 5, 100, message, colors.blue)
  PrimeUI.textBox(term.current(), 3, h - 2, w - 4, 1, "Press enter to continue.", colors.white)

  local key_pressed
  if keys_possible.n == 0 then
    keys_possible = {keys.enter, n = 1}
  end

  local function action(key)
    return function()
      key_pressed = key
      PrimeUI.resolve("done")
    end
  end

  for i = 1, keys_possible.n do
    PrimeUI.keyAction(keys_possible[i], action(keys_possible[i]))
  end

  PrimeUI.run()

  return key_pressed
end
