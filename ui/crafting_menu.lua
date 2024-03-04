local recipe_handler = require "recipe_handler"
local machines_common = require "ui.machines.common"
local items_common = require "ui.items.common"

local crafting_output = require "ui.util.good_response"
local search = require "ui.util.search"
local get_integer = require "ui.util.get_integer"
local catch_error = require "ui.util.catch_error"

local file_helper = require "file_helper"

--- Crafting menu -> Search for an item, then get a crafting plan for it.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  local item_ids = recipe_handler.get_items()

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

  local preferred_recipes = {}

  for _, item_id in ipairs(item_ids) do
    -- Step 3:
    local item_recipes = recipe_handler.get_recipes(item_id)

    -- Step 4:
    if item_recipes then
      if #item_recipes > 1 then
        local preferred_recipe = nil ---@type Recipe?
        local preferred_machine = nil ---@type MachineData?

        for i, recipe in ipairs(item_recipes) do
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
          preferred_recipes[item_id] = preferred_recipe
        end
      end
    end
  end

  -- Get all item names from item ids
  local item_names = {}
  for _, item_id in ipairs(item_ids) do
    table.insert(item_names, items_common.get_item_name(item_id))
  end

  table.sort(item_names)

  while true do
    local item_name = search("Select item to craft", item_names)
    if not item_name then
      return
    end

    local item_id = items_common.get_item_id(item_name)

    if not item_id then
      error(("Item ID for item %s does not exist."):format(item_name), 0)
    end

    local needed = get_integer("How many do you need?", 1, 1)
    if not needed then
      return
    end

    catch_error(function()
      local exclusions = {}
      recipe_handler.build_recipe_graph()
      repeat
        local plan = recipe_handler.get_first_recipe(
          item_id,
          needed,
          100,
          preferred_recipes,
          exclusions
        )
        local key_pressed
        if plan then
          local text_plan = table.concat(recipe_handler.get_plan_as_text(plan, 1), "\n")
          file_helper:write("crafting_plan.txt", text_plan)

          text_plan = text_plan .. "\n\nThe above crafting plan was also written to crafting_plan.txt."

          key_pressed = crafting_output(
            ("Crafting Plan - x%d %s"):format(needed, item_name),
            text_plan,
            "Press enter to continue, or 1 to select items to remove the cost of from the plan.",
            keys.enter,
            keys.one
          )

          if key_pressed == keys.one then
            sleep() -- Clear the event queue, so we don't get a key press from the previous menu.
            local needed_items = recipe_handler.get_needed_items(plan)

            -- Remove the main item from the list of needed items.
            for i, needed_item in ipairs(needed_items) do
              if needed_item == item_name then
                table.remove(needed_items, i)
                break
              end
            end

            local exclusion = search("Select item to remove/re-add.", needed_items)
            if exclusion then
              exclusions[exclusion] = not exclusions[exclusion]
            end
          end
        else
          error("No recipe found.", 0)
        end
      until key_pressed == keys.enter
    end)
  end
end
