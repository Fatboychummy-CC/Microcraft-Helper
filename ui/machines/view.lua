local common = require "ui.machines.common"
local search = require "ui.util.search"
local good_response = require "ui.util.good_response"


--- View machine menu -> Search for a machine by name, then display the name and preference level.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  local machine_names = {}
  local machine_names_to_ids = {}
  for _, data in pairs(common.machines) do
    table.insert(machine_names, data.name)
    machine_names_to_ids[data.name] = data.id
  end

  while true do
    local machine = search("Select Machine", machine_names)
    if machine then
      local data = common.machines[machine_names_to_ids[machine]]
      good_response("Machine Info", ("Name: %s\nPreference: %d\nID: %d"):format(machine, data.preference_level, data.id))
    else
      return
    end
  end
end
