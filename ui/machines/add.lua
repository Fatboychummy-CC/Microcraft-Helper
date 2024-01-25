local machines_common = require "ui.machines.common"
local get_text = require "ui.util.get_text"

--- Add machine menu -> allows you to add a machine to the list of machines.
---@param run_menu fun(name: string) The function to run another menu (Unneeded in this menu, but added for consistency)
return function(run_menu)
  local machine_name = get_text("Microcraft Helper", "Enter a name for the machine.")
  if machine_name then
    machines_common.add_machine(machine_name)
  end
end