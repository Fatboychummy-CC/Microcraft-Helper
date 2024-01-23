local PrimeUI = require "PrimeUI_cherrypicked"
local quick_sub_menu = require "ui.quick_sub_menu"

--- Main menu UI
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  quick_sub_menu("Main Menu", {
    {
      name = "Items",
      description = "Add, remove, or edit items, as well as their recipes.",
      action = function()
        run_menu("items.menu")
      end
    },
    {
      name = "Machines",
      description = "Add, remove, or edit machines, as well as their preference level.",
      action = function()
        run_menu("machines.menu")
      end
    },
    {
      name = "Crafting",
      description = "Craft items.",
      action = function()
        run_menu("crafting_menu")
      end
    }
  }, true, false, "Exit")
end