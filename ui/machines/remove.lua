local common = require "ui.machines.common"
local search = require "ui.util.search"
local catch_error = require "ui.util.catch_error"
local confirmation_menu = require "ui.util.confirmation_menu"
local recipe_handler = require "recipe_handler"


--- Remove machine menu: Search for a machine by name, then remove it, if the user confirms.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  local machine_names = {}
  local machine_names_to_ids = {}

  for _, data in pairs(common.machines) do
    table.insert(machine_names, data.name)
    machine_names_to_ids[data.name] = data.id
  end

  local machine = search("Select machine for removal.", machine_names)
  if machine then
    -- Given the machine id, search for recipes which use this machine and count
    -- them and store them
    local machine_id = machine_names_to_ids[machine]
    local invalid_recipe_count = 0
    local invalidated_recipes = {}
    for _, item_id in pairs(recipe_handler.get_items()) do
      local recipes = recipe_handler.get_recipes(item_id)

      if recipes then
        for _, recipe in pairs(recipes) do
          if recipe.machine == machine_id then
            invalid_recipe_count = invalid_recipe_count + 1
            table.insert(invalidated_recipes, recipe.id)
          end
        end
      end
    end

    if confirmation_menu(("Remove %s? This will also delete %d recipe(s)."):format(machine, invalid_recipe_count)) then
      catch_error(common.remove_machine, machine_id)
      for _, recipe_id in pairs(invalidated_recipes) do
        catch_error(recipe_handler.remove_recipe, recipe_id)
      end

      recipe_handler.save()
      common.save()
    end
  end
end
