local recipe_handler = require "recipe_handler"

local common = require "ui.items.common"
local get_item_details = require "ui.items.get_item_details"
local catch_error = require "ui.util.catch_error"

--- Edit machine menu -> Search for a machine by name, then edit the name and preference level.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  local recipe_data = get_item_details()
  
  if recipe_data then
    recipe_handler.insert(recipe_data)
    recipe_handler.save()
  end
end