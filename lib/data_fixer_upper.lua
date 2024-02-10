local file_helper = require "file_helper":instanced("data")
local recipe_handler = require "recipe_handler"
local machines_common = require "ui.machines.common"

local fixer_upper = {}

--- Fix old style machine data (no id) to new style (with id). This also needs to update recipes to use the id instead of the name.
function fixer_upper.machine_id_fixer()
  term.setTextColor(colors.gray)
  print("Backing up save files...")
  machines_common.backup_save()
  recipe_handler.backup_save()

  ---@type table<integer, MachineData>
  local new_data = {}

  ---@type table<string, integer>
  local machine_names_to_ids = {}

  print("Fixing machine data...")
  for _, v in pairs(machines_common.machines) do
    if v.id then
      -- This machine is OK, we can just copy its data over.
      new_data[v.id] = v
      machine_names_to_ids[v.name] = v.id
    elseif v.name:lower() == "crafting table" then
      -- This is the crafting table, it's special and needs ID 0.
      v.id = 0
      new_data[0] = v
      machine_names_to_ids[v.name] = 0
    else
      -- This machine's data is old and needs to be updated.
      local machine = machines_common.new_machine(v.name, v.preference_level)
      new_data[machine.id] = machine
      machine_names_to_ids[v.name] = machine.id
    end
  end

  machines_common.machines = new_data

  -- Get the lookup table for all recipes.
  local lookup = recipe_handler.get_lookup()

  -- Update the recipes to use the new machine IDs.
  print("Fixing recipe data...")
  local i = 0
  for name, recipes in pairs(lookup) do
    for _, recipe in ipairs(recipes) do
      i = i + 1

      if type(recipe.machine) == "number" then
        -- This recipe data is OK, we can just skip it.
      else
        if not machine_names_to_ids[recipe.machine] then
          error(("Data fixer upper failed: No ID was generated for machine %s."):format(recipe.machine), 0)
        end
        recipe_handler.edit_recipe(name, recipe.random_id, {
          machine = machine_names_to_ids[recipe.machine]
        })
      end
    end
  end

  print("Fixed", i, "recipes.")

  recipe_handler.save()
  machines_common.save()
  term.setTextColor(colors.white)
  print("Data fixer upper has finished.")
  sleep(5)

end

function fixer_upper.check()
  term.clear()
  term.setCursorPos(1, 1)
  -- Check if the machines have IDs.
  for k, v in pairs(machines_common.machines) do
    if not v.id or type(k) == "string" then
      term.setCursorPos(1, 1)
      term.setTextColor(colors.orange)
      print("Running machine ID fixer...")

      fixer_upper.machine_id_fixer()
      break
    end
  end
end

return fixer_upper