local recipe_handler = require "recipe_handler"
local items_common = require "ui.items.common"

local search = require "ui.util.search"
local good_response = require "ui.util.good_response"
local confirmation_menu = require "ui.util.confirmation_menu"

--- This menu allows items to be excluded from the final count.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  -- Get a list of all uncraftable items
  local item_ids = recipe_handler.get_uncraftable_items()

  -- Get all the names of the items.
  local item_names = {}

  for _, item_id in pairs(item_ids) do
    local item_name = items_common.get_item_name(item_id)

    if not item_name then
      error(("Item name for item ID %d does not exist."):format(item_id), 0)
    end

    table.insert(item_names, item_name)
  end

  -- Sort the item names
  table.sort(item_names)

  local last_search

  while true do
    -- Search for an item
    local selected_item_name = search("Select Item", item_names, false, last_search)

    if not selected_item_name then
      return
    end

    -- Get the item ID
    local item_id = items_common.get_item_id(selected_item_name)

    if not item_id then
      error(("Item ID for item %s does not exist."):format(selected_item_name), 0)
    end

    -- Check if the user wants to exclude the item
    local exclude = confirmation_menu(("Exclude %s from final counts?"):format(selected_item_name))
    items_common.edit_item(item_id, nil, exclude)
    good_response(
      exclude and "Item excluded" or "Item exclusion removed.",
      ("%s %s from final counts."):format(
        exclude and "Excluded" or "Removed exclusion for",
        selected_item_name
      )
    )
  end
end
