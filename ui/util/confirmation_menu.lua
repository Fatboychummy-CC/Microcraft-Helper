local PrimeUI = require "PrimeUI_cherrypicked"

--- Get a confirmation from the user (true for "yes", false for "no").
---@param title string The title of the confirmation menu.
---@return boolean confirmation The user's confirmation choice.
return function(title)
  local w = term.getSize()
  local current_selection = false

  -- Set up the page.
  PrimeUI.clear()
  require "ui.title" (title)

  -- Draw the confirmation labels.
  PrimeUI.textBox(term.current(), 4, 7, 5, 1, " Yes", current_selection and colors.green or colors.white,
    current_selection and colors.white or colors.black)
  PrimeUI.textBox(term.current(), 4, 9, 5, 1, " No", not current_selection and colors.red or colors.white,
    not current_selection and colors.white or colors.black)
  local function action()
    current_selection = not current_selection

    PrimeUI.textBox(term.current(), 4, 7, 5, 1, " Yes", current_selection and colors.green or colors.white,
      current_selection and colors.white or colors.black)
    PrimeUI.textBox(term.current(), 4, 9, 5, 1, " No", not current_selection and colors.red or colors.white,
      not current_selection and colors.white or colors.black)
  end

  PrimeUI.keyAction(keys.up, action)
  PrimeUI.keyAction(keys.down, action)
  PrimeUI.keyAction(keys.right, action)
  PrimeUI.keyAction(keys.left, action)
  PrimeUI.keyAction(keys.enter, "confirm")

  PrimeUI.run()


  return current_selection
end
