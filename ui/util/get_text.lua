--- A menu to get some text from the user.

local PrimeUI = require "PrimeUI_cherrypicked"

--- Allows you to get text from the user.
---@param menu_name string The name of the menu.
---@param menu_subtitle string The subtitle of the menu.
---@param default_text string? The default text to show in the input box.
---@return string? text The text the user entered, or nil if the user cancelled.
return function(menu_name, menu_subtitle, default_text)
  local w = term.getSize()

  -- Set up the page.
  PrimeUI.clear()
  PrimeUI.label(term.current(), 3, 2, menu_name)
  PrimeUI.horizontalLine(term.current(), 3, 3, #menu_name + 2)
  PrimeUI.label(term.current(), 3, 5, menu_subtitle)

  -- Draw a box around the input box.
  PrimeUI.borderBox(term.current(), 4, 7, w - 6, 1)

  -- Add a textbox below the input box
  PrimeUI.textBox(term.current(), 4, 9, w - 6, 1, "Press END to cancel.")
  PrimeUI.keyAction(keys["end"], "cancel")

  -- Add the text input box.
  local input_name = "Text Box"
  PrimeUI.inputBox(term.current(), 4, 7, w - 6, input_name, nil, nil, nil, nil, nil, default_text)

  local input, box, value = PrimeUI.run()

  if input == "inputBox" and box == input_name then
    return value
  end
end