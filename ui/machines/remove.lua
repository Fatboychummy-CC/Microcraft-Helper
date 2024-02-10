local common = require "ui.machines.common"
local search = require "ui.util.search"
local catch_error = require "ui.util.catch_error"
local confirmation_menu = require "ui.util.confirmation_menu"


--- Remove machine menu: Search for a machine by name, then remove it, if the user confirms.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  local machine_names = {}
  local machine_names_to_ids = {}
  for _, data in pairs(common.machines) do
    table.insert(machine_names, data.name)
    machine_names_to_ids[data.name] = data.id
  end

  local machine = search("Select machine for removal.", machine_names)
  if machine then
    if confirmation_menu(("Remove %s?"):format(machine)) then
      catch_error(common.remove_machine, machine_names_to_ids[machine])
    end
  end
end
