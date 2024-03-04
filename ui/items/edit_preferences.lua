local recipe_handler = require "recipe_handler"

local search = require "ui.util.search"
local good_response = require "ui.util.good_response"
local items_common = require "ui.items.common"

--- Item preference menu -> Show items with multiple recipes, then select one to be preferred.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  -- Get the list of item names
  local item_names = recipe_handler.get_items()

  -- Now, search through the list of names for recipes with multiple recipes
  local duplicate_item_names = {}

  for _, item_id in pairs(item_names) do
    local recipes = recipe_handler.get_recipes(item_id)

    -- Get the name of the item
    local item_name = items_common.get_item_name(item_id)

    if not item_name then
      error(("Item name for item ID %d does not exist."):format(item_id), 0)
    end

    if recipes and #recipes > 1 then
      table.insert(duplicate_item_names, item_name)
    end
  end

  -- Sort the recipe names
  table.sort(duplicate_item_names)

  -- Search for a recipe
  local item_name = search("Select Item", duplicate_item_names)

  if not item_name then return end

  -- Get the ID of the item.
  local item_id = items_common.get_item_id(item_name)

  if not item_id then
    error(("Item ID for item %s does not exist."):format(item_name), 0)
  end

  -- Get the list of recipes for the item
  local item_recipes = recipe_handler.get_recipes(item_id)

  if not item_recipes then
    error(("Recipes for item %s (%d) do not exist."):format(item_name, item_id), 0)
  end

  -- Now we need to collect all recipes for the items -- we will combine the item name with its ID to make a unique key
  local recipe_names = {}

  for _, item_recipe in pairs(item_recipes) do
    table.insert(recipe_names, ("%s (%s)"):format(item_name, item_recipe.id))
  end

  -- Sort the recipe names
  table.sort(recipe_names)

  -- Search for a recipe
  local recipe = search("Select Recipe", recipe_names)

  if not recipe then return end

  -- Get the item name and recipe ID from the recipe name
  local result_item_name, recipe_id = recipe:match("^(.+) %((.-)%)$")
  recipe_id = tonumber(recipe_id)

  if not recipe_id then
    error(("Recipe ID for recipe %s does not exist."):format(recipe), 0)
  end

  -- Get the recipe data
  local recipe_data = recipe_handler.get_recipe(recipe_id)

  if not recipe_data then
    error(("Recipe data for recipe ID %d does not exist."):format(recipe_id), 0)
  end

  for _, item_recipe in pairs(item_recipes) do
    recipe_handler.edit_recipe(item_recipe.id, {preferred = false})
  end
  recipe_handler.edit_recipe(recipe_id, {preferred = true})
  recipe_handler.save()

  good_response("Set preference.", ("The preference for %s has been set to the requested recipe. It will be used from now on whenever a recipe requires the item."):format(result_item_name))
end
