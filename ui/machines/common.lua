--- Common functionality between the various machine menus.

local file_helper = require "file_helper" :instanced("data")

---@class MachineData
---@field name string The name of the machine.
---@field preference_level number The preference level of the machine.

local common = {
  machine_list = {}
}

local SAVE_FILE = "machines.lson"

--- Load the list of machine names from the file.
---@return table<string, MachineData> list The list of machines.
function common.load()
  local list = file_helper:unserialize(SAVE_FILE, {})
  common.machine_list = list
  return list
end

--- Save the list of machine names to the file.
function common.save()
  file_helper:serialize(SAVE_FILE, common.machine_list, true)
end

--- Add a machine to the list.
---@param name string The name of the machine to add.
function common.add_machine(name)
  -- Disallow addition of crafting table.
  if name == "Crafting Table" then
    return
  end

  common.machine_list[name] {
    name = name,
    preference_level = 0
  }
  common.save()
end

--- Remove a machine from the list.
---@param name string The name of the machine to remove.
function common.remove_machine(name)
  -- Disallow removal of crafting table.
  if name == "Crafting Table" then
    return
  end

  common.machine_list[name] = nil
  common.save()
end

return common