local quick_sub_menu = require "ui.quick_sub_menu"

--- Machine menu -> allows you to add, remove, or edit machines. The "Crafting Table" machine is not removable.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  quick_sub_menu("Machines", {
    {
      name = "Add Machine",
      description = "Add a machine to the system so it can be used in recipes.",
      action = function()
        run_menu("machines.add")
      end
    },
    {
      name = "Edit Machine",
      description = "Edit a machine's name and preference level.",
      action = function()
        run_menu("machines.edit")
      end
    },
    {
      name = "Remove Machine",
      description = "Remove a machine from the system.",
      action = function()
        run_menu("machines.remove")
      end
    }
  }, true, false, "Go Back")
end