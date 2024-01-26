local recipe_handler = require "recipe_handler"

local get_item_details = require "ui.items.get_item_details"
local catch_error = require "ui.util.catch_error"
local search = require "ui.util.search"

--- Edit item menu -> Search for an item by name, then edit its recipe.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  -- Get the list of item names
  local item_names = recipe_handler.get_items()

  -- Now we need to collect all recipes for the items -- we will combine the item name with its random ID to make a unique key
  local recipe_names = {}

  for _, item_name in pairs(item_names) do
    local recipes = recipe_handler.get_recipes(item_name)
    if recipes then
      for _, recipe in pairs(recipes) do
        table.insert(recipe_names, ("%s (%s)"):format(item_name, recipe.random_id))
      end
    end
  end

  -- Sort the recipe names
  table.sort(recipe_names)

  -- Search for a recipe
  local recipe = search("Select Recipe", recipe_names)

  if recipe then
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

    -- Get the new recipe data
    local new_recipe_data = catch_error(get_item_details, recipe_data, recipe_data.result.name)

    if not new_recipe_data then
      return
    end

    recipe_handler.edit_recipe(item_name, recipe_id, new_recipe_data)
    recipe_handler.save()
  end
end
