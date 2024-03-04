local recipe_handler = require "recipe_handler"
local items_common = require "ui.items.common"

local good_response  = require "ui.util.good_response"
local search = require "ui.util.search"
local confirm = require "ui.util.confirmation_menu"

--- Remove machine menu -> Search for a machine by name, then remove it, if the user confirms.
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
  local recipe = search("Select Recipe", recipe_names)

  if recipe then
    -- Get the item name and recipe ID from the recipe name
    local item_name, recipe_id = recipe:match("^(.+) %((.-)%)$")
    recipe_id = tonumber(recipe_id)

    if not recipe_id then
      error(("Recipe ID for recipe %s does not exist."):format(recipe), 0)
    end

    if not confirm(("Remove %s?"):format(recipe)) then
      return
    end

    recipe_handler.remove_recipe(recipe_id)
    recipe_handler.save()
    good_response("Item removed", ("Removed item %s."):format(recipe))
  end
end
