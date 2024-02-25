local file_helper = require "file_helper":instanced("data")
local recipe_handler = require "recipe_handler"
local machines_common = require "ui.machines.common"

local fixer_upper = {}

--- Fix duplicate machine names by determining which id the machines should "collapse" to
function fixer_upper.duplicate_machine_name_fixer()
  print("Fixing duplicate machine names...")

  ---@type table<string, integer>
  local machine_names_to_ids = {["Crafting Table"] = 0}
  local machine_count = 0
  for id, v in pairs(machines_common.machines) do
    if v.name:lower() == "crafting table" then
      -- This is the crafting table, it's special and needs ID 0.
      -- It is already in the lookup table.
    elseif machine_names_to_ids[v.name] then
      -- A duplicate was found.
    else
      -- This machine is OK, we can just copy its data over.
      machine_names_to_ids[v.name] = v.id or id -- It is not this module's job to fix the ID, that's the machine_id_fixer's job.
    end
  end

  local new_machine_lookup = {}
  -- For each machine in our name-to-id lookup, we need to go through the
  -- machines_common.machines and ensure only one exists.
  for name, id in pairs(machine_names_to_ids) do
    for k, v in pairs(machines_common.machines) do
      if v.name:lower() == name:lower() and v.id ~= id then
        -- This machine is a duplicate, we need to remove it (aka ignore it)
        machine_count = machine_count + 1
      else
        -- Not a duplicate, we can add it to the new lookup table.
        new_machine_lookup[id] = v
      end
    end
  end

  machines_common.machines = new_machine_lookup

  machines_common.save()
  print("Fixed", machine_count, "machines.")
end

--- Fix old style machine data (no id) to new style (with id). This also needs to update recipes to use the id instead of the name.
function fixer_upper.machine_id_fixer()
  print("Fixing machine data...")

  ---@type table<integer, MachineData>
  local new_data = {}

  ---@type table<string, integer>
  local machine_names_to_ids = {}
  local machine_count = 0
  for id, v in pairs(machines_common.machines) do
    if v.name == "Crafting Table" then
      -- This is the crafting table, it's special and needs ID 0.
      v.id = 0
      new_data[0] = v
      machine_names_to_ids[v.name] = 0
    elseif type(id) == "string" or not v.id or id ~= v.id then
      -- This machine's data is old and needs to be updated.
      machine_count = machine_count + 1
      -- This machine has an error, we should just generate a new ID for it.
      local machine = machines_common.new_machine(v.name, v.preference_level)
      new_data[machine.id] = machine
      machine_names_to_ids[v.name] = machine.id
    else
      -- This machine is OK, we can just copy its data over.
      new_data[v.id] = v
      machine_names_to_ids[v.name] = v.id
    end
  end

  machines_common.machines = new_data
  print("Fixed", machine_count, "machines.")

  -- Get the lookup table for all recipes.
  local lookup = recipe_handler.get_lookup()

  -- Update the recipes to use the new machine IDs.
  print("Fixing recipe data...")
  local recipe_count = 0
  for name, recipes in pairs(lookup) do
    for _, recipe in ipairs(recipes) do
      if type(recipe.machine) == "number" then
        -- This recipe data is OK, we can just skip it.
      else
        if not machine_names_to_ids[recipe.machine] then
          error(("Data fixer upper failed: No ID was generated for machine %s."):format(recipe.machine), 0)
        end
        recipe_count = recipe_count + 1
        recipe_handler.edit_recipe(name, recipe.random_id, {
          machine = machine_names_to_ids[recipe.machine]
        })
      end
    end
  end

  print("Fixed", recipe_count, "recipes.")

  recipe_handler.save()
  machines_common.save()
end


--- Fix recipe data that uses machine names instead of IDs.
function fixer_upper.recipe_machine_fixer()
  -- Update the recipes to use the new machine IDs.
  print("Fixing recipe data...")

  -- Create a lookup table of machine names to IDs.
  local machine_names_to_ids = {}
  for id, data in pairs(machines_common.machines) do
    machine_names_to_ids[data.name] = id
  end

  -- Get the lookup table for all recipes.
  local lookup = recipe_handler.get_lookup()
  local i = 0
  for name, recipes in pairs(lookup) do
    for _, recipe in ipairs(recipes) do
      i = i + 1

      if type(recipe.machine) == "number" then
        -- This recipe data is OK, we can just skip it.
      else
        local machine = machine_names_to_ids[recipe.machine]
        if not machine then
          error(("Data fixer upper failed: No ID known for machine %s."):format(recipe.machine), 0)
        end
        recipe_handler.edit_recipe(name, recipe.random_id, {
          machine = machine
        })
      end
    end
  end

  print("Fixed", i, "recipes.")

  recipe_handler.save()
end

local checks = {}

function checks.duplicate_machine_names()
  local machine_names = {}
  for _, v in pairs(machines_common.machines) do
    if machine_names[v.name:lower()] then
      return true
    end
    machine_names[v.name:lower()] = true
  end
  return false
end

function checks.machine_id_needed()
  for k, v in pairs(machines_common.machines) do
    if not v.id or type(k) == "string" or type(v.id) == "string" then
      return true
    end
  end
  return false
end

function checks.recipe_machine_needed()
  local lookup = recipe_handler.get_lookup()
  for _, recipes in pairs(lookup) do
    for _, recipe in ipairs(recipes) do
      if type(recipe.machine) == "string" then
        return true
      end
    end
  end
  return false
end

function fixer_upper.check()
  term.clear()
  term.setCursorPos(1, 1)
  local duplicate_machine_names = checks.duplicate_machine_names()
  local machine_id_needed = checks.machine_id_needed()
  local recipe_machine_needed = checks.recipe_machine_needed()

  if machine_id_needed or recipe_machine_needed or duplicate_machine_names then
    term.setTextColor(colors.white)
    term.setCursorPos(1, 1)
    term.clear()

    print("Data Fixer Upper needs to run, press 'q' to quit, or any other key to continue.")
    print("Your data will be backed up.")
    print("\nModules:")
    if duplicate_machine_names then
      print("- Duplicate machine names")
    end
    if machine_id_needed then
      print("- Machine IDs")
    end
    if recipe_machine_needed then
      print("- Recipe machine IDs")
    end
    sleep() -- Ensure the event queue is cleared.
    local ev, key = os.pullEvent("key")
    if key == keys.q then
      sleep()
      error("", 0) -- Close the program.
    end

    term.setTextColor(colors.lightGray)
    print("Backing up save files...")
    machines_common.backup_save()
    recipe_handler.backup_save()

    if duplicate_machine_names then
      term.setTextColor(colors.orange)
      print("Running machine ID fixer...")

      fixer_upper.machine_id_fixer()
    end

    if machine_id_needed then
      term.setTextColor(colors.orange)
      print("Running machine ID fixer...")
      term.setTextColor(colors.lightGray)
      fixer_upper.machine_id_fixer()
    end

    if recipe_machine_needed then
      term.setTextColor(colors.orange)
      print("Running recipe machine fixer...")
      term.setTextColor(colors.lightGray)
      fixer_upper.recipe_machine_fixer()
    end

    if checks.duplicate_machine_names() then
      term.setTextColor(colors.red)
      print("Data fixer upper caused a duplicate machine name, fixing...")
      term.setTextColor(colors.lightGray)
      fixer_upper.duplicate_machine_name_fixer()
    end

    term.setTextColor(colors.white)
    print("Data fixer upper has finished. Press any key to close.")
    sleep() -- Ensure the event queue is cleared.
    os.pullEvent("key")
    sleep()

    error("", 0) -- Close the program.
  end
end

return fixer_upper