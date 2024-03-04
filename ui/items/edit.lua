local recipe_handler = require "recipe_handler"
local items_common = require "ui.items.common"

local get_item_details = require "ui.items.get_item_details"
local catch_error = require "ui.util.catch_error"
local search = require "ui.util.search"
local good_response  = require "ui.util.good_response"

--- Edit item menu -> Search for an item by name, then edit its recipe.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  -- Get the list of item names
  local item_ids = recipe_handler.get_items()

  -- Now we need to collect all recipes for the items -- we will combine the item name with its random ID to make a unique key
  local recipe_names = {}

  for _, item_id in pairs(item_ids) do
    local recipes = recipe_handler.get_recipes(item_id)
    local item_name = items_common.get_item_name(item_id)

    if not item_name then
      error(("Item name for item ID %d does not exist."):format(item_id), 0)
    end

    if recipes then
      for _, recipe in pairs(recipes) do
        table.insert(recipe_names, ("%s (%s)"):format(item_name, recipe.id))
      end
    end
  end

  -- Sort the recipe names
  table.sort(recipe_names)

  -- Search for a recipe
  local selected_recipe = search("Select Recipe", recipe_names)

  if selected_recipe then
    -- Get the item name and recipe ID from the recipe name
    local item_name, recipe_id = selected_recipe:match("^(.+) %((.-)%)$")
    recipe_id = tonumber(recipe_id)

    if not recipe_id then
      error(("Recipe ID for recipe %s does not exist."):format(selected_recipe), 0)
    end

    -- Get the recipe data
    local recipe_data = recipe_handler.get_recipe(recipe_id)

    if not recipe_data then
      error(("Recipe data for recipe %s does not exist."):format(selected_recipe), 0)
    end

    -- Get the new recipe data
    local ok, new_recipe_data = catch_error(get_item_details, recipe_data, item_name)

    if not ok or not new_recipe_data then
      return
    end

    recipe_handler.edit_recipe(recipe_id, new_recipe_data)
    recipe_handler.save()

    local new_item_name = items_common.get_item_name(new_recipe_data.result.id)

    good_response("Item edited", ("Edited item %s (outputs %d)."):format(new_item_name, new_recipe_data.result.amount))
  end
end
