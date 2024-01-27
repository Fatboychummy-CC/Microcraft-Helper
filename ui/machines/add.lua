local common = require "ui.machines.common"
local get_machine_details = require "ui.machines.get_machine_details"
local catch_error = require "ui.util.catch_error"
local good_response = require "ui.util.good_response"

--- Edit machine menu -> Search for a machine by name, then edit the name and preference level.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  local ok, name, preference = catch_error(get_machine_details)

  if ok and name and preference then
    if catch_error(common.add_machine, {
      name = name,
      preference_level = preference
    }) then
      good_response("Machine edited", ("Edited machine %s with preference level %d."):format(name, preference))
    end
  end
end
