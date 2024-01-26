local recipe_handler = require "recipe_handler"

local search = require "ui.util.search"
local good_response = require "ui.util.good_response"

--- Item preference menu -> Show items with multiple recipes, then select one to be preferred.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  -- Get the list of item names
  local item_names = recipe_handler.get_items()

  -- Now, search through the list of names for recipes with multiple recipes
  local duplicate_item_names = {}

  for _, item_name in pairs(item_names) do
    local recipes = recipe_handler.get_recipes(item_name)
    if recipes and #recipes > 1 then
      table.insert(duplicate_item_names, item_name)
    end
  end

  -- Sort the recipe names
  table.sort(duplicate_item_names)

  -- Search for a recipe
  local item = search("Select Item", duplicate_item_names)

  if not item then return end

  -- Get the list of recipes for the item
  local recipes = recipe_handler.get_recipes(item)

  if not recipes then
    error("WHY DOESN'T IT EXIST?????")
  end

  -- Now we need to collect all recipes for the items -- we will combine the item name with its random ID to make a unique key
  local recipe_names = {}

  for _, recipe in pairs(recipes) do
    table.insert(recipe_names, ("%s (%s)"):format(item, recipe.random_id))
  end

  -- Sort the recipe names
  table.sort(recipe_names)

  -- Search for a recipe
  local recipe = search("Select Recipe", recipe_names)

  if not recipe then return end


  -- Get the item name and recipe ID from the recipe name
  local item_name, recipe_id = recipe:match("^(.+) %((.-)%)$")
  recipe_id = tonumber(recipe_id)

  if not recipe_id then
    error("You somehow managed to get a recipe ID that is not a number. How did you do that?", 0)
  end

  -- Get the recipe data
  local recipe_data = recipe_handler.get_recipe(item_name, recipe_id)

  if not recipe_data then
    error("Between then and now how THE HECK DOES IT NOT EXIST?????????", 0)
  end

  for _, recipe in pairs(recipes) do
    recipe_handler.edit_recipe(item_name, recipe.random_id, {preferred = false})
  end
  recipe_handler.edit_recipe(item_name, recipe_id, {preferred = true})
  recipe_handler.save()

  good_response("Set preference.", ("The preference for %s has been set to the requested recipe. It will be used from now on whenever a recipe requires the item."):format(item))
end
