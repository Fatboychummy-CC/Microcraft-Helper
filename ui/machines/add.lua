local common = require "ui.machines.common"
local get_machine_details = require "ui.machines.get_machine_details"
local catch_error = require "ui.util.catch_error"

--- Edit machine menu -> Search for a machine by name, then edit the name and preference level.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  local name, preference = catch_error(get_machine_details)

  if name and preference then
    catch_error(common.add_machine, {
      name = name,
      preference_level = preference
    })
  end
end