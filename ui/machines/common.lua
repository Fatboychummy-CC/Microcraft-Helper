--- Common functionality between the various machine menus.

local file_helper = require "file_helper" :instanced("data")

---@class MachineData
---@field name string The name of the machine.
---@field preference_level number The preference level of the machine.

---@class machines-common
---@field machines table<string, MachineData> A lookup of machine names to their data.
local common = {
  machines = {
    ["crafting table"] = {
      name = "Crafting Table",
      preference_level = 0
    }
  }
}

local SAVE_FILE = "machines.lson"

--- Load the list of machine names from the file.
---@return table<string, MachineData> list The list of machines.
function common.load()
  local list = file_helper:unserialize(SAVE_FILE, {})
  common.machines = list

  -- Always ensure the crafting table exists
  if not common.machines["crafting table"] then
    common.machines["crafting table"] = {
      name = "Crafting Table",
      preference_level = 0
    }
  end

  return list
end

--- Save the list of machine names to the file.
function common.save()
  file_helper:serialize(SAVE_FILE, common.machines, true)
end

--- Edit information about a machine.
---@param old_name string The name of the machine to edit.
---@param new_name string The new name of the machine.
---@param new_preference number The new preference level of the machine.
function common.edit_machine(old_name, new_name, new_preference)
  local actual_name = new_name
  old_name = old_name:lower()
  new_name = new_name:lower()

  -- First, ensure we aren't trying to change some other machine into the crafting table, or the crafting table into some other machine.
  if old_name == "crafting table" and new_name ~= "crafting table" then
    error("The crafting table's name is reserved and cannot be changed.", 2)
  end
  if old_name ~= "crafting table" and new_name == "crafting table" then
    error("Cannot change other machine into crafting table, as the crafting table is reserved.", 2)
  end

  -- Next, ensure that the new name isn't already taken.
  if old_name ~= new_name and common.machines[new_name] then
    error(("The name '%s' is already taken."):format(actual_name), 2)
  end

  -- Next, ensure that the old machine exists.
  if not common.machines[old_name] then
    error(("The machine '%s' does not exist."):format(actual_name), 2)
  end

  -- Finally, edit the machine.
  local machine = common.machines[old_name] or {}
  machine.name = actual_name
  machine.preference_level = new_preference

  -- And remove the old entry, then re-add it.
  common.machines[old_name] = nil
  common.machines[new_name] = machine

  common.save()
end

--- Add a machine to the list.
---@param name string|MachineData The name of the machine to add.
function common.add_machine(name)
  local preference_level = 0
  if type(name) == "table" then
    preference_level = name.preference_level or 0
    name = name.name
  end ---@cast name string

  local actual_name = name
  name = name:lower()

  -- Disallow addition of crafting table.
  if name == "crafting table" then
    error("Cannot add crafting table, as the crafting table is reserved.", 2)
  end

  -- Ensure that the name isn't already taken.
  if common.machines[name] then
    error(("The name '%s' is already taken."):format(actual_name), 2)
  end

  common.machines[name] = {
    name = actual_name,
    preference_level = preference_level
  }
  common.save()
end

--- Remove a machine from the list.
---@param name string The name of the machine to remove.
function common.remove_machine(name)
  local actual_name = name
  name = name:lower()

  -- Disallow removal of crafting table.
  if name == "crafting table" then
    error("Cannot remove crafting table, as the crafting table is reserved.", 2)
  end

  -- Ensure that the machine exists.
  if not common.machines[name] then
    error(("The machine '%s' does not exist."):format(actual_name), 2)
  end

  common.machines[name] = nil
  common.save()
end

return common