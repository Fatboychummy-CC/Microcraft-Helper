--- Common functionality between the various machine menus.

local file_helper = require "file_helper" :instanced("data")

local common = {
  machine_list = {}
}

local SAVE_FILE = "machines.lson"

--- Load the list of machine names from the file.
---@return table<string> list The list of machines.
function common.load()
  local list = file_helper:unserialize(SAVE_FILE, {})
  common.machine_list = list
  return list
end

--- Save the list of machine names to the file.
function common.save()
  file_helper:write(SAVE_FILE, textutils.serialize(common.machine_list))
end

--- Add a machine to the list.
---@param name string The name of the machine to add.
function common.add_machine(name)
  common.remove_machine(name) -- ensure no duplicates are added.
  table.insert(common.machine_list, name)
  common.save()
end

--- Remove a machine from the list.
---@param name string The name of the machine to remove.
function common.remove_machine(name)
  for i, v in ipairs(common.machine_list) do
    if v == name then
      table.remove(common.machine_list, i)
    end
  end
  common.save()
end

return common