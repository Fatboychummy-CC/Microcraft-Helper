local common = require "ui.machines.common"
local search = require "ui.util.search"
local get_machine_details = require "ui.machines.get_machine_details"
local catch_error = require "ui.util.catch_error"


--- Edit machine menu -> Search for a machine by name, then edit the name and preference level.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  local machine_names = {}
  for name in pairs(common.machines) do
    table.insert(machine_names, name)
  end

  local machine = search("Select Machine", machine_names)
  if machine then
    local new_name, new_preference = catch_error(get_machine_details, common.machines[machine])
    if new_name and new_preference then
      catch_error(common.edit_machine,
        machine,
        new_name,
        new_preference
      )
    end
  end
end