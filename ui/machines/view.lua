local common = require "ui.machines.common"
local search = require "ui.util.search"
local good_response = require "ui.util.good_response"


--- View machine menu -> Search for a machine by name, then display the name and preference level.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  local machine_names = {}
  for _, data in pairs(common.machines) do
    table.insert(machine_names, data.name)
  end

  while true do
    local machine = search("Select Machine", machine_names)
    if machine then
      good_response("Machine Info", ("Name: %s\nPreference: %d"):format(machine, common.machines[machine:lower()].preference_level))
    else
      return
    end
  end
end
