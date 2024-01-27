local recipe_handler = require "recipe_handler"

local get_item_details = require "ui.items.get_item_details"
local catch_error = require "ui.util.catch_error"
local good_response = require "ui.util.good_response"

--- Add item menu -> Add an item and its recipe.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  local ok, recipe_data = catch_error(get_item_details)

  if ok and recipe_data then
    recipe_handler.insert(recipe_data)
    recipe_handler.save()
    good_response("Item added", ("Added item %s (outputs %d)."):format(recipe_data.result.name, recipe_data.result.amount))
  end
end
