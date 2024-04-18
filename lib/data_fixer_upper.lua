local file_helper = require "file_helper":instanced("data")
local recipe_handler = require "recipe_handler"
local machines_common = require "ui.machines.common"
local items_common = require "ui.items.common"

local fixer_upper = {}

local fixes = {}

--- Fix duplicate machine names by determining which id the machines should "collapse" to
function fixes.duplicate_machine_names()
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
function fixes.machine_id_needed()
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
        recipe_handler.edit_recipe(recipe.id, {
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
function fixes.recipe_machine_needed()
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
        recipe_handler.edit_recipe(recipe.id, {
          machine = machine
        })
      end
    end
  end

  print("Fixed", i, "recipes.")

  recipe_handler.save()
end

--- Fix item data that is not generated.
function fixes.item_data_not_generated()
  -- Search all recipes for items that don't have data.
  -- We are looking for the following:
  -- 1. recipe.id is nil
  -- 1. a) recipe.random_id exists
  -- 1. fix: if random_id exists, set id to random_id, otherwise generate a new id.
  -- 2. recipe.result.id is nil
  -- 2. a) recipe.result.name exists instead
  -- 2. fix: if name exists, set id to the id of the item with that name -- we may need to generate a new id if the item doesn't exist.
  -- 2. fail: if name doesn't exist, we can't fix this
  -- 3. Check each ingredient, ingredient.id is nil
  -- 3. a) ingredient.name exists
  -- 3. fix: if name exists, set id to the id of the item with that name -- we may need to generate a new id if the item doesn't exist.
  -- 3. fail: if name doesn't exist, we can't fix this

  -- Ensure that items common loaded OK, if not, fail.
  local loaded_ok, err = pcall(items_common.load)
  if not loaded_ok then
    error(("Data fixer upper failed: Cannot load items_common: %s"):format(err), 0)
  end

  -- Manually load the data from the file.
  local lines = file_helper:get_lines(recipe_handler.SAVE_FILE)
  local recipes = {}

  for _, line in ipairs(lines) do
    local recipe = textutils.unserialize(line) --[[@as Recipe?]]
    table.insert(recipes, recipe)
  end

  -- Check for invalid data.
  local recipe_count = 0

  local used_recipe_ids = {} -- For manually generating IDs.

  for i, recipe in ipairs(recipes) do
    -- 1.
    if not recipe.id then
      recipe_count = recipe_count + 1
      if recipe.random_id then
        recipe.id = recipe.random_id

        -- 1. a)
        recipe.random_id = nil
      else
        repeat
          recipe.id = math.random(-1000000, 1000000)
        until not used_recipe_ids[recipe.id]
      end

      used_recipe_ids[recipe.id] = true
    end

    -- 2.
    if not recipe.result.id then
      recipe_count = recipe_count + 1
      if recipe.result.name then
        local id = items_common.get_item_id(recipe.result.name)
        if id then
          recipe.result.id = id
        else
          recipe.result.id = items_common.add_item(recipe.result.name)
        end

        -- 2. a)
        recipe.result.name = nil
      else
        error(("Data fixer upper failed: Both ID and name are missing for recipe %d."):format(i), 0)
      end
    end

    -- 3.
    for j, ingredient in ipairs(recipe.ingredients) do
      if not ingredient.id then
        recipe_count = recipe_count + 1
        if ingredient.name then
          local id = items_common.get_item_id(ingredient.name)
          if id then
            ingredient.id = id
          else
            ingredient.id = items_common.add_item(ingredient.name)
          end

          -- 3. a)
          ingredient.name = nil
        else
          error(("Data fixer upper failed: Both ID and name are missing for ingredient %d in recipe %d."):format(j, i), 0)
        end
      end
    end
  end

  -- Save the data back to the file.
  local serialized = {}
  for _, recipe in ipairs(recipes) do
    table.insert(serialized, textutils.serialize(recipe, {compact=true}))
  end

  file_helper:write(recipe_handler.SAVE_FILE, table.concat(serialized, "\n"))

  -- Save the items data back to the file.
  items_common.save()
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

--- Check if item data is not generated.
function checks.item_data_not_generated()
    -- Search all recipes for items that don't have data.
  -- We are looking for the following:
  -- 1. recipe.id is nil
  -- 1. a) recipe.random_id exists
  -- 2. recipe.result.id is nil
  -- 2. a) recipe.result.name exists instead
  -- 3. Check each ingredient, ingredient.id is nil
  -- 3. a) ingredient.name exists
  --
  -- We also want to strip out any extra data, so if recipe.id is not nil, but recipe.random_id exists (or recipe.name) we want to remove it.

  -- Manually load the data from the file.
  local lines = file_helper:get_lines(recipe_handler.SAVE_FILE)
  local recipes = {}

  for _, line in ipairs(lines) do
    local recipe = textutils.unserialize(line) --[[@as Recipe?]]
    table.insert(recipes, recipe)
  end

  -- Check for invalid data.
  for _, recipe in ipairs(recipes) do
    -- Missing cases
    if not recipe.id or not recipe.result.id then
      return true
    end

    -- Extra cases
    if recipe.random_id or recipe.result.name then
      return true
    end

    -- Ingredients...
    for _, ingredient in ipairs(recipe.ingredients) do
      -- Extra and missing case
      if not ingredient.id or ingredient.name then
        return true
      end
    end
  end

  return false
end

function fixer_upper.check()
  local results = {}
  local needs_run = false
  for check_name, checker in pairs(checks) do
    local out = checker()
    results[check_name] = out
    if out then
      needs_run = true
    end
  end

  if needs_run then
    term.setTextColor(colors.white)
    print() -- Ensure the cursor is on the screen.

    print("Data Fixer Upper needs to run, press 'q' to quit, or any other key to continue.")
    term.setTextColor(colors.yellow)
    print("  Your data will be backed up.")

    -- Check if any of the backup files exist already.

    -- Machines common backup
    if file_helper:exists(machines_common.BACKUP_FILE) then
      term.setBackgroundColor(colors.red)
      term.setTextColor(colors.white)
      write("  Warning: Machine data backup exists, and will be overwritten.")
      term.setBackgroundColor(colors.black)
      term.setTextColor(colors.white)
      print()
    end

    -- Recipe handler backup
    if file_helper:exists(recipe_handler.BACKUP_FILE) then
      term.setBackgroundColor(colors.red)
      term.setTextColor(colors.white)
      write("  Warning: Recipe data backup exists, and will be overwritten.")
      term.setBackgroundColor(colors.black)
      term.setTextColor(colors.white)
      print()
    end

    -- Items common backup
    if file_helper:exists(items_common.BACKUP_FILE) then
      term.setBackgroundColor(colors.red)
      term.setTextColor(colors.white)
      write("  Warning: Item data backup exists, and will be overwritten.")
      term.setBackgroundColor(colors.black)
      term.setTextColor(colors.white)
      print()
    end


    print("\nModules:")
    for check_name, result in pairs(results) do
      term.setTextColor(result and colors.white or colors.gray)
      print("-", check_name, result and "needs to be run." or "is OK.")
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
    items_common.backup_save()

    for check_name, fixer in pairs(fixes) do
      if results[check_name] then
        term.setTextColor(colors.white)
        print("Running", check_name, "fixer...")
        term.setTextColor(colors.lightGray)

        fixer()

        term.setTextColor(colors.white)
        print("Finished", check_name, "fixer.")
      end
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