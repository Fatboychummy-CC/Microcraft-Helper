--- Common functionality between the various machine menus.

--------------------------------------------------------------------------------
--                    Lua Language Server Type Definitions                    --
--------------------------------------------------------------------------------

---@class item_data An item and its associated data.
---@field name string The name of the item.
---@field id integer The unique identifier of the item.

--------------------------------------------------------------------------------
--                    End Language Server Type Definitions                    --
--------------------------------------------------------------------------------

local file_helper = require "file_helper":instanced("data")

---@class items_common
local common = {
  ---@type table<integer, item_data>
  item_lookup = {},

  SAVE_FILE = "items.lson",
  BACKUP_FILE = "items.lson.bak"
}

--- Generate a unique id for an item.
---@return integer id The unique id.
local function generate_unique_id()
  local id

  repeat
    id = math.random(-1000000, 1000000)
  until not common.item_ids[id]

  return id
end

--- Add a new item to the list of items.
---@param name string The name of the item.
---@return integer id The unique id of the item.
function common.add_item(name)
  local id = generate_unique_id()
  local item = {name = name, id = id}

  common.item_lookup[id] = item
  return id
end

--- Remove an item from the list of items.
---@param id integer The unique id of the item.
function common.remove_item(id)
  common.item_lookup[id] = nil
end

--- Get the list of items.
---@return table<integer, item_data> The list of items.
function common.get_items()
  return common.item_lookup
end

--- Get the name of an item.
---@param id integer The unique id of the item.
---@return string? name The name of the item, or nil if it does not exist.
function common.get_item_name(id)
  return common.item_lookup[id] and common.item_lookup[id].name
end

--- Get the unique id of an item.
---@param name string The name of the item.
---@return integer? id The unique id of the item, or nil if it does not exist.
function common.get_item_id(name)
  for id, item in pairs(common.item_lookup) do
    if item.name == name then
      return id
    end
  end
end

--- Load the recipes and items from a file.
function common.load()
  -- Convert from a list to save a little bit of space
  local list = file_helper:unserialize(common.SAVE_FILE, {})
  common.item_lookup = {}

  for _, item in ipairs(list) do
    common.item_lookup[item.id] = item
  end
end

--- Save the recipes and items to a file.
function common.save()
  -- Convert to a list to save a little bit of space
  local list = {}
  for _, item in pairs(common.item_lookup) do
    table.insert(list, item)
  end

  file_helper:serialize(common.SAVE_FILE, list)
end

--- Backup the recipes and items to a file.
function common.backup_save()
  file_helper:write(common.BACKUP_FILE, file_helper:get_all(common.SAVE_FILE))
end

return common
