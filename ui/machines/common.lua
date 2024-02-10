--- Common functionality between the various machine menus.

local file_helper = require "file_helper":instanced("data")

---@class MachineData
---@field name string The name of the machine.
---@field preference_level number The preference level of the machine.
---@field id integer The unique ID of the machine.

---@class machines-common
---@field machines table<integer, MachineData> A lookup of machine names to their data.
local common = {
  machines = {
    [0] = {
      name = "Crafting Table",
      preference_level = 0,
      id = 0,
    }
  }
}

local SAVE_FILE = "machines.lson"

--- Generate a unique integer for a machine.
---@return integer id The unique integer.
local function gen_unique_int()
  -- Technically O(inf) but in practice O(1)
  local id
  repeat
    id = math.random(-1000000, 1000000)
  until not common.machines[id]

  return id
end

--- Create a new machine object.
---@param name string The name of the machine.
---@return MachineData machine The new machine object.
function common.new_machine(name, preference_level)
  ---@type MachineData
  return {
    name = name,
    id = gen_unique_int(),
    preference_level = preference_level or 0
  }
end

--- Load the list of machine names from the file.
---@return table<integer, MachineData> list The list of machines.
function common.load()
  local list = file_helper:unserialize(SAVE_FILE, {})
  common.machines = list

  -- Always ensure the crafting table exists
  if not common.machines[0] then
    common.machines[0] = common.new_machine("Crafting Table")
  end

  return list
end

--- Save the list of machine names to the file.
function common.save()
  file_helper:serialize(SAVE_FILE, common.machines, true)
end

--- Edit information about a machine.
---@param id integer The ID of the machine to edit.
---@param new_name string? The new name of the machine. Supply nil if only editing the other parameter.
---@param new_preference number? The new preference level of the machine. Leave empty if only editing the other parameter.
function common.edit_machine(id, new_name, new_preference)
  local actual_name = new_name

  -- First, ensure we aren't trying to change some other machine into the crafting table, or the crafting table into some other machine.
  if id == 0 then
    error("The crafting table's name is reserved and cannot be changed.", 2)
  end
  if new_name and new_name:lower() == "crafting table" then
    error("Cannot change other machine into crafting table, as the crafting table is reserved.", 2)
  end

  -- Ensure we aren't changing the name to the name of a machine that exists.
  if new_name then
    for _, machine in pairs(common.machines) do
      if machine.name:lower() == new_name:lower() and machine.id ~= id then
        error(("A machine with the name '%s' already exists."):format(new_name), 2)
      end
    end
  end

  -- Ensure that the machine exists.
  if not common.machines[id] then
    error(("The machine with ID %d does not exist."):format(id), 2)
  end

  -- Finally, edit the machine.
  local machine = common.machines[id]
  machine.name = actual_name or machine.name
  machine.preference_level = new_preference or machine.preference_level

  common.save()
end

--- Add a machine to the list.
---@param name string The name of the machine to add.
---@param preference_level number? The preference level of the machine. Defaults to 0.
function common.add_machine(name, preference_level)
  local preference_level = 0

  -- Disallow addition of crafting table.
  if name:lower() == "crafting table" then
    error("Cannot add crafting table, as the crafting table is reserved.", 2)
  end

  -- Ensure that the machine does not already exist.
  for _, machine in pairs(common.machines) do
    if machine.name:lower() == name:lower() then
      error(("A machine with the name '%s' already exists."):format(name), 2)
    end
  end

  local machine = common.new_machine(name, preference_level)
  common.machines[machine.id] = machine
  common.save()
end

--- Remove a machine from the list.
---@param id integer The ID of the machine to remove.
function common.remove_machine(id)

  -- Disallow removal of crafting table.
  if id == 0 then
    error("Cannot remove crafting table, as the crafting table is reserved.", 2)
  end

  -- Ensure that the machine exists.
  if not common.machines[0] then
    error(("The machine id %d does not exist."):format(id), 2)
  end

  common.machines[id] = nil
  common.save()
end

--- Backup the save file.
function common.backup_save()
  file_helper:write(SAVE_FILE .. ".bak", file_helper:get_all(SAVE_FILE))
end

return common
