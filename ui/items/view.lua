local recipe_handler = require "recipe_handler"
local machines_common = require "ui.machines.common"
local items_common = require "ui.items.common"

local good_response = require "ui.util.good_response"
local search = require "ui.util.search"

--- View item menu -> Search for an item by name, then display the item's information.
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

  local last_recipe = nil

  while true do
    -- Search for a recipe
    local recipe = search("Select Recipe", recipe_names, false, last_recipe)

    if recipe then
      -- Get the item name and recipe ID from the recipe name
      local item_name, recipe_id = recipe:match("^(.+) %((.-)%)$")
      recipe_id = tonumber(recipe_id)

      if not recipe_id then
        error("You somehow managed to get a recipe ID that is not a number. How did you do that?", 0)
      end

      -- Get the recipe data
      local recipe_data = recipe_handler.get_recipe(recipe_id)

      if not recipe_data then
        error("Between then and now how THE HECK DOES IT NOT EXIST?????????", 0)
      end

      local ingredients_text = {}
      local ingredient_formatter = "  x%d %s %s"
      for _, ingredient in pairs(recipe_data.ingredients) do
        local ingredient_name = items_common.get_item_name(ingredient.id)

        if not ingredient_name then
          error(("Ingredient name for item ID %d does not exist."):format(ingredient.id), 0)
        end
        table.insert(ingredients_text, ingredient_formatter:format(ingredient.amount, ingredient_name, ingredient.fluid and "(fluid)" or ""))
      end

      -- Find the machine by its id
      local machine_name = machines_common.machines[recipe_data.machine] and machines_common.machines[recipe_data.machine].name or "Unknown Machine"

      good_response(
        recipe, 
        ("Machine: %s\nOutputs: %d    Preferred? %s\nID: %d\nRecipe:\n%s"):format(
          machine_name,
          recipe_data.result.amount,
          recipe_data.preferred and "Yes" or "No",
          recipe_data.id,
          table.concat(ingredients_text, "\n")
        )
      )

      last_recipe = item_name
    else
      return
    end
  end
end
