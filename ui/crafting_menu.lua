local recipe_handler = require "recipe_handler"

local machines_common = require "ui.machines.common"
local crafting_output = require "ui.util.crafting_plan_menu"
local search = require "ui.util.search"
local get_integer = require "ui.util.get_integer"
local catch_error = require "ui.util.catch_error"

local file_helper = require "file_helper"

--- Crafting menu -> Search for an item, then get a crafting plan for it.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  local item_names = recipe_handler.get_items()

  -- Calculate current recipe selections.
  -- Steps:
  -- 1. Get a list of all items with recipes.
  -- 2. Get all machines.
  -- 3. For each item, get a list of all recipes.
  -- 4. For each recipe, check if it is the preferred recipe.
  --  4a. If it is, add it to the list of preferred recipes.
  --  4b. If there are no preferred recipes, check the machine each recipe is made in, and add the highest machine preference recipe to the list.
  --  4c. If multiple machines have the same preference level, just grab the first machine.
  -- 5. If there were no preferred recipes or machines in step 4, add the first recipe to the list.

  -- Step 1 is already complete.
  -- Step 2:
  local machines = machines_common.machines

  -- Step 3:
  local recipes = recipe_handler.get_lookup()

  -- Step 4:
  local preferred_recipes = {}

  for _, item in ipairs(item_names) do
    local item_recipes = recipes[item.name]

    if item_recipes then
      if #item_recipes > 1 then
        local preferred_recipe = nil ---@type Recipe?
        local preferred_machine = nil ---@type MachineData?

        for _, recipe in ipairs(item_recipes) do
          if recipe.preferred then
            preferred_recipe = recipe
            break
          end

          if not preferred_machine or preferred_machine.preference_level < machines[recipe.machine].preference_level then
            preferred_machine = machines[recipe.machine]
            preferred_recipe = recipe
          end
        end

        if preferred_recipe then
          table.insert(preferred_recipes, preferred_recipe)
        end
      end
    end
  end


  while true do
    local item = search("Select Item", item_names)
    if not item then
      return
    end

    local needed = get_integer("How many do you need?", 1, 1)
    if not needed then
      return
    end

    catch_error(function()
      recipe_handler.build_recipe_graph()
      local plan = recipe_handler.get_first_recipe(item, needed, 100, preferred_recipes)
      if plan then
        local text_plan = table.concat(recipe_handler.get_plan_as_text(plan, 1), "\n")
        file_helper:write("crafting_plan.txt", text_plan)

        text_plan = text_plan .. "\n\nThe above crafting plan was also written to crafting_plan.txt."

        crafting_output(("Crafting Plan - x%d %s"):format(needed, item), text_plan)
      else
        error("No recipe found.", 0)
      end
    end)
  end
end
