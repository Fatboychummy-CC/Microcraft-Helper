local PrimeUI = require "PrimeUI_cherrypicked"
local machines_common = require "ui.machines.common"

--- Add machine menu -> allows you to add a machine to the list of machines.
---@param run_menu fun(name: string) The function to run another menu (Unneeded in this menu, but added for consistency)
return function(run_menu)
  -- Set up the page.
  PrimeUI.clear()
  PrimeUI.label(term.current(), 3, 2, "Microcraft Helper")
  PrimeUI.horizontalLine(term.current(), 3, 3, #("Microcraft Helper") + 2)
  PrimeUI.label(term.current(), 3, 5, "Add Machine")


  -- Draw a box around the input box.
  PrimeUI.borderBox(term.current(), 4, 7, 20, 1)

  -- Add the text input box.
  PrimeUI.inputBox(term.current(), 4, 7, 20, "Machine Name") -- how do i get text from this

  local input, box, name = PrimeUI.run()

  if input == "inputBox" and box == "Machine Name" then
    -- Add the machine to the list.
    machines_common.add_machine(name)
  end
end