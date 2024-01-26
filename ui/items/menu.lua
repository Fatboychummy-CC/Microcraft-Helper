local quick_sub_menu = require "ui.quick_sub_menu"

--- Items menu -> allows you to add, remove, or edit Items.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  quick_sub_menu("Items", {
    {
      name = "Add Item",
      description = "Add an item and its recipe.",
      action = function()
        run_menu("items.add")
      end
    },
    {
      name = "View Items",
      description = "View information about an item and its recipe.",
      action = function()
        run_menu("items.view")
      end
    },
    {
      name = "Edit Item",
      description = "Edit an item and its recipe.",
      action = function()
        run_menu("items.edit")
      end
    },
    {
      name = "Edit Recipe Preferences",
      description = "Edit the preferred recipe for an item with multiple recipes. These override machine preferences, if any are set.",
      action = function()
        run_menu("items.edit_preferences")
      end
    },
    {
      name = "Remove Item",
      description = "Remove a recipe.",
      action = function()
        run_menu("items.remove")
      end
    }
  }, true, false, "Go Back")
end
