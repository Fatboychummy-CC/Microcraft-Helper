local common = require "ui.machines.common"
local search = require "ui.util.search"

--- Edit machine menu -> First, search for a machine by its name.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  local machine_names = {}
  for name in pairs(common.machines) do
    table.insert(machine_names, name)
  end

  local machine = search("Microcraft Helper", "Select Machine", machine_names)
  if machine then
    print()
    term.clear()
    print(("Editing %s"):format(machine))
  end
end