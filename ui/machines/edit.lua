local common = require "ui.machines.common"
local search = require "ui.util.search"
local get_machine_details = require "ui.machines.get_machine_details"
local catch_error = require "ui.util.catch_error"
local good_response = require "ui.util.good_response"


--- Edit machine menu -> Search for a machine by name, then edit the name and preference level.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  local machine_names = {}
  local machine_names_to_ids = {}
  for _, data in pairs(common.machines) do
    table.insert(machine_names, data.name)
    machine_names_to_ids[data.name] = data.id
  end

  -- Sort the machine names
  table.sort(machine_names)

  local machine = search("Select Machine", machine_names)
  if machine then
    local ok, new_name, new_preference = catch_error(get_machine_details, common.machines[machine_names_to_ids[machine]])
    if ok and new_name and new_preference then
      if catch_error(common.edit_machine,
        machine_names_to_ids[machine],
        new_name,
        new_preference
      ) then
        good_response("Machine edited", ("Edited machine %s with preference level %d."):format(new_name, new_preference))
      end
    end
  end
end
