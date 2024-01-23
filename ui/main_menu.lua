local PrimeUI = require "PrimeUI_cherrypicked"

--- Main menu UI
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  print("We in here in the main menu")
  PrimeUI.clear()
  PrimeUI.label(term.current(), 3, 2, "Microcraft Helper")
  PrimeUI.horizontalLine(term.current(), 3, 3, #("Microcraft Helper") + 2)
  PrimeUI.label(term.current(), 3, 5, "What would you like to do?")
  local selected = 1
  PrimeUI.selectionBox(term.current(), 4, 7, 40, 3, {
    "View recipes",
    "Craft an item",
    "Exit"
  }, function(sel)
    selected = sel
  end)
  PrimeUI.keyAction(keys.enter, "done")
  local a, b, result = PrimeUI.run()
  print()
  print(a, b, result)
  print(selected)
  if result == "exit" then
    print("We exit bois")
    return
  end
  run_menu(result)
end