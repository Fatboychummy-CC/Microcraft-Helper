--- Common functionality between the various machine menus.

local file_helper = require "file_helper" :instanced("data")

local common = {
  machine_list = {}
}

--- Load the list of machine names from the file.
---@return table<string> list The list of machines.
function common.load_machine_list()
  local list = file_helper:unserialize("machines.list", {})
  common.machine_list = list
  return list
end

--- Save the list of machine names to the file.
function common.save_machine_list()
  file_helper:write("machines.list", textutils.serialize(common.machine_list))
end

--- Add a machine to the list.
---@param name string The name of the machine to add.
function common.add_machine(name)
  table.insert(common.machine_list, name)
  common.save_machine_list()
end

--- Remove a machine from the list.
---@param name string The name of the machine to remove.
function common.remove_machine(name)
  for i, v in ipairs(common.machine_list) do
    if v == name then
      table.remove(common.machine_list, i)
      common.save_machine_list()
      return
    end
  end
end

return common