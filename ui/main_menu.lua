local quick_sub_menu = require "ui.quick_sub_menu"
local catch_error = require "ui.util.catch_error"

--- Main menu UI
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  catch_error(quick_sub_menu, "Main Menu", {
    {
      name = "Items and Recipes",
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