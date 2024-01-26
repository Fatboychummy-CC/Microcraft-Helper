local recipe_handler = require "recipe_handler"

local search = require "ui.util.search"
local confirm = require "ui.util.confirmation_menu"

--- Remove machine menu -> Search for a machine by name, then remove it, if the user confirms.
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

    if not confirm(("Remove %s?"):format(recipe)) then
      return
    end

    recipe_handler.remove_recipe(item_name, recipe_id)
    recipe_handler.save()
  end
end
