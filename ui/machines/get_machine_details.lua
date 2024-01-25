local common = require "ui.machines.common"
local get_text = require "ui.util.get_text"
local get_integer = require "ui.util.get_integer"

--- Get information about a machine.
---@param machine_data MachineData The machine data to edit.
---@return string? new_name The new name of the machine.
---@return integer? new_preference The new preference level of the machine.
return function(machine_data)
  machine_data = machine_data or {name="", preference_level=0}
  local new_name = get_text( "Enter machine name.", machine_data.name)
  if not new_name then
    return
  end

  local new_preference = get_integer( "Enter preference level.", machine_data.preference_level)

  if not new_preference then
    return
  end

  return new_name, new_preference
end