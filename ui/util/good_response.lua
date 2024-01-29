local PrimeUI = require "PrimeUI_cherrypicked"

local util = require "util"

--- Display a message to the user.
---@param subtitle string The subtitle of the menu.
---@param message string The message to display.
return function(subtitle, message)
  local w, h = term.getSize()

  -- Set up the page.
  PrimeUI.clear()
  local scrollbox = PrimeUI.scrollBox(term.current(), 3, 7, w - 4, h - 10, util.get_line_count(message, w - 5) + 3, true, true)
  require "ui.title" (subtitle, colors.green, colors.green)

  PrimeUI.textBox(scrollbox, 1, 1, w - 5, 100, message, colors.blue)
  PrimeUI.textBox(term.current(), 3, h - 2, w - 4, 1, "Press enter to continue.", colors.white)

  PrimeUI.keyAction(keys.enter, "done")

  PrimeUI.run()
end
