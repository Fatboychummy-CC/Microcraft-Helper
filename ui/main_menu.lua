local PrimeUI = require "PrimeUI_cherrypicked"
local quick_sub_menu = require "ui.quick_sub_menu"

--- Main menu UI
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  quick_sub_menu("Main Menu", {
    {
      name = "Items",
      action = function()
        run_menu("items_menu")
      end
    },
    {
      name = "Machines",
      action = function()
        run_menu("machines_menu")
      end
    },
    {
      name = "Crafting",
      action = function()
        run_menu("crafting_menu")
      end
    }
  }, true, false, "Exit")
end