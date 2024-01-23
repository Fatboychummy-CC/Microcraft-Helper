local quick_sub_menu = require "ui.quick_sub_menu"

--- Machine menu -> allows you to add, remove, or edit machines. The "Crafting Table" machine is not removable.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  quick_sub_menu("Machines", {
    {
      name = "Add Machine",
      action = function()
        run_menu("machines.add")
      end
    },
    {
      name = "Edit Machine",
      action = function()
        run_menu("machines.edit")
      end
    },
    {
      name = "Remove Machine",
      action = function()
        run_menu("machines.remove")
      end
    }
  }, true, false, "Go Back")
end