--- The RecipeHandler class is used to manage the crafting recipes given to the
--- program.

---@alias LuaType
---| '"nil"'
---| '"boolean"'
---| '"number"'
---| '"string"'
---| '"table"'
---| '"function"'
---| '"thread"'
---| '"userdata"'

local expect = require "cc.expect".expect --[[@as fun(pos: number, value: any, ...: LuaType)]]
local file_helper = require "file_helper" :instanced("data")
local graph = require "graph"
local shallow_serialize = require "graph.shallow_serialize"
local util = require "util"
local machines_common = require "ui.machines.common"
local items_common = require "ui.items.common"

--------------------------------------------------------------------------------
--                    Lua Language Server Type Definitions                    --
--------------------------------------------------------------------------------

---@class RecipeGraph : Graph
---@field nodes RecipeGraphNode[] A list of all nodes in the graph.

---@class RecipeGraphNode : GraphNode
---@field value CraftingPlanStep The currently planned recipe for the node.
---@field connections RecipeGraphNode[] The nodes connected to this node.

---@alias RecipeList Recipe[]

---@class Recipe A single crafting recipe.
---@field result RecipeIngredient The resultant item.
---@field ingredients RecipeIngredient[] The ingredients required to craft the item.
---@field machine integer The id of the machine used to craft the item. Defaults to `0` (Crafting Table).
---@field enabled boolean Whether or not the recipe is enabled.
---@field preferred boolean Whether or not the recipe is preferred.
---@field id number A unique ID used to identify the recipe in the graph, mainly used when there are multiple recipes for the same item.

---@class RecipeIngredient A single ingredient in the recipe.
---@field id integer The id of the item.
---@field amount number The amount of the ingredient.
---@field fluid boolean Whether or not the ingredient is a fluid.

---@class FluidRecipeIngredient : RecipeIngredient A single ingredient in the recipe (fluid).
---@field amount number The amount of the ingredient, in millibuckets.
---@field fluid true Whether or not the ingredient is a fluid.

---@alias RecipeLookup table<integer, Recipe[]>

---@class CraftingPlan A plan containing all the steps, in order, to craft the given item.
---@field item integer The id of the item to craft.
---@field output_count number The amount of items that will be outputted.
---@field steps CraftingPlanStep[] The steps to craft the item.

---@class FinalizedCraftingPlan : CraftingPlan A finalized crafting plan, with all the recipes filled in.
---@field raw_material_cost MaterialCost The cost of the raw materials needed to craft the item.

---@class CraftingPlanStep A single step in the crafting plan.
---@field item integer The id of the item to craft.
---@field output_count number The amount of items that will be outputted.
---@field needed number The amount of the item crafted that are needed in future steps.
---@field crafts number The amount of times to repeat the crafting process.
---@field recipe Recipe? The recipe to use to craft the item, if the item can be crafted.

---@class MultiCraftPlanStep A single step in a crafting plan, that can have multiple recipes.
---@field item integer The id of the item to craft.
---@field output_count number The amount of items that will be outputted.
---@field needed number The amount of the item crafted that are needed in future steps.
---@field crafts number The amount of times to repeat the crafting process.
---@field recipes Recipe[] The recipes that can be used to craft the item.

---@alias MaterialCost table<integer, number>

--------------------------------------------------------------------------------
--                  End Lua Language Server Type Definitions                  --
--------------------------------------------------------------------------------

local _DEBUG = false
local function prints(s, ...)
  if _DEBUG then
    local inputs = table.pack(...)
    for i = 1, inputs.n do
      inputs[i] = tostring(inputs[i])
    end
    print(("%s"):format((" "):rep(s)) .. table.concat(inputs, " "))
  end
end

---@type RecipeList
local recipes = {}
---@type RecipeLookup
local lookup = {}
---@type RecipeGraph
local recipe_graph = graph.new() --[[@as RecipeGraph]]

--- Create a smaller version of a recipe list with unneeded data removed (things like `fluid = false` can be nil, so it isn't included in the output data).
---@return table recipes The ensmallified list of recipes.
local function ensmallify()
  local smallified = {}

  for i = 1, #recipes do
    local recipe = recipes[i]
    local small_recipe = {
      result = {
        id = recipe.result.id,
        amount = recipe.result.amount,
        fluid = recipe.result.fluid
      },
      ingredients = {},
      id = recipe.id,
    }

    if recipe.preferred then
      small_recipe.preferred = true
    end

    if recipe.machine == 0 then
      small_recipe.machine = nil
    else
      small_recipe.machine = recipe.machine
    end

    if small_recipe.result.fluid == false then
      small_recipe.result.fluid = nil
    end

    if small_recipe.result.amount == 1 then
      small_recipe.result.amount = nil
    end

    for j = 1, #recipe.ingredients do
      local ingredient = recipe.ingredients[j]
      small_recipe.ingredients[j] = {
        id = ingredient.id,
        amount = ingredient.amount,
        fluid = ingredient.fluid,
      }

      if small_recipe.ingredients[j].fluid == false then
        small_recipe.ingredients[j].fluid = nil
      end

      if small_recipe.ingredients[j].amount == 1 then
        small_recipe.ingredients[j].amount = nil
      end
    end

    table.insert(smallified, small_recipe)
  end

  return smallified
end

--- Build/rebuild the recipes list into a lookup table of output items (keys) to a list of recipes (values).
local function build_lookup()
  lookup = {} ---@type RecipeLookup

  for i = 1, #recipes do
    local recipe = recipes[i]

    if not lookup[recipe.result.id] then
      lookup[recipe.result.id] = {}
    end

    table.insert(lookup[recipe.result.id], recipe)
  end
end

--- Set values for needed, crafts, and output count in each node of the graph to zero.
local function zero_recipe_graph()
  for _, node in ipairs(recipe_graph.nodes) do
    node.value.needed = 0
    node.value.crafts = 0
    node.value.output_count = 0
  end
end

---@class RecipeHandler
local RecipeHandler = {
  SAVE_FILE = "recipes.list",
  BACKUP_FILE = "recipes.list.bak",
  MIN_ID = -1000000,
  MAX_ID = 1000000
}

--- Generate a unique id for a recipe.
---@return integer id The unique id.
local function generate_unique_id()
  local id

  repeat
    id = math.random(RecipeHandler.MIN_ID, RecipeHandler.MAX_ID)
  until not lookup[id]

  return id
end

--- Load the recipes from the given file. WARNING: This wipes the currently loaded recipe list first, then loads the recipes.
function RecipeHandler.load()
  recipes = {} ---@type RecipeList
  local lines = file_helper:get_lines(RecipeHandler.SAVE_FILE)

  for i = 1, lines.n do
    local line = lines[i]
    local recipe, err = RecipeHandler.parse_recipe(line)

    if recipe then
      table.insert(recipes, recipe)
    else
      error(("Failed to parse recipe on line %d: %s\n\n%s"):format(i, line, err))
    end

    if i % 1000 == 0 then
      -- This program really shouldn't be used with huuuge recipe lists,
      -- but we'll support it anyways.
      print(("Loaded %d recipes"):format(i))
      os.queueEvent("recipe_load_progress", i)
      os.pullEvent("recipe_load_progress")
    end
  end

  build_lookup()
end

--- Parse a recipe from a string.
---@param line string The string to parse the recipe from.
---@return Recipe? recipe The recipe parsed from the string.
---@return string? error The error message if the recipe could not be parsed.
function RecipeHandler.parse_recipe(line)
  local recipe = textutils.unserialize(line)

  if not recipe then
    return nil, "Failed to unserialize recipe."
  end

  if not recipe.result then
    return nil, "No result found in recipe."
  end

  if not recipe.result.id then
    return nil, "No result id found in recipe."
  end

  if not recipe.enabled then
    recipe.enabled = false
  end

  if not recipe.result.amount then
    recipe.result.amount = 1
  end

  if recipe.result.fluid == nil then
    recipe.result.fluid = false
  end

  if not recipe.ingredients then
    return nil, "No ingredients found in recipe."
  end

  if not recipe.machine then
    recipe.machine = 0
  end

  for i = 1, #recipe.ingredients do
    local ingredient = recipe.ingredients[i]

    if not ingredient.id then
      return nil, ("No id found for ingredient %d in recipe."):format(i)
    end

    if not ingredient.amount then
      ingredient.amount = 1
    end

    if ingredient.fluid == nil then
      ingredient.fluid = false
    end
  end

  return recipe --[[@as Recipe]]
end

--- Insert a recipe into the recipe list.
---@param recipe Recipe The recipe to insert.
function RecipeHandler.insert(recipe)
  ---@FIXME confirm the recipe is valid
  table.insert(recipes, recipe)
  if not lookup[recipe.result.id] then
    lookup[recipe.result.id] = {}
  end
  table.insert(lookup[recipe.result.id], recipe)
end

--- Save the recipes to the given file.
function RecipeHandler.save()
  local lines = {}

  local recipes_small = ensmallify()

  for i = 1, #recipes_small do
    local recipe = recipes_small[i]
    local line = textutils.serialize(recipe, { compact = true })

    table.insert(lines, line)
  end

  file_helper:write(RecipeHandler.SAVE_FILE, table.concat(lines, "\n"))
end

--- Build/rebuild the recipe graph.
function RecipeHandler.build_recipe_graph()
  -- For each recipe, we need to create a node in the graph. We also need to
  -- connect each node to the nodes of the ingredients.

  -- We can do this in two passes.
  -- 1. Create all the nodes.
  -- 2. Connect all the nodes.

  build_lookup()

  recipe_graph = graph.new() --[[@as RecipeGraph]]

  -- First pass: Create all the nodes. One node for each recipe for an item.
  for item_id, item_recipes in pairs(lookup) do
    for i = 1, #item_recipes do
      local recipe = item_recipes[i]
      recipe_graph:add_node({
        item = item_id,
        recipe = util.deep_copy(recipe),
        needed = 0,
        crafts = 0,
        output_count = 0
      }) --[[@as RecipeGraphNode]]
    end
  end

  -- Second pass: Connect all the nodes via their ingredient lists.
  -- We also create nodes for ingredients that don't have recipes here.
  for i = 1, #recipe_graph.nodes do
    local node = recipe_graph.nodes[i]
    local recipe = node.value.recipe

    if recipe then
      for j = 1, #recipe.ingredients do
        local ingredient = recipe.ingredients[j]
        local ingredient_id = ingredient.id
        local ingredient_nodes = recipe_graph:find_nodes(function(n) return n.value.item == ingredient_id end) --[[ @as RecipeGraphNode[] ]]

        if #ingredient_nodes == 0 then
          -- Ingredient doesn't have a recipe, create a node for it.
          local new_node = recipe_graph:add_node({
            item = ingredient_id,
            recipe = nil,
            needed = 0,
            crafts = 0,
            output_count = 0
          }) --[[@as RecipeGraphNode]]

          -- and connect it
          new_node:connect(node)
        else
          for k = 1, #ingredient_nodes do
            local ingredient_node = ingredient_nodes[k]
            ingredient_node:connect(node)
          end
        end
      end
    end
  end
end

--- Clean up a crafting plan by removing duplicate entries. Modifies in-place.
--- Also clean up any "Craft 0 of x item" entries.
---@param plan CraftingPlan The crafting plan to clean up.
local function clean_crafting_plan(plan)
  local seen = {}

  local i = 0
  while i <= #plan.steps do
    i = i + 1

    local step = plan.steps[i]
    if not step then break end

    if seen[step.recipe.id] or step.needed == 0 then
      table.remove(plan.steps, i)

      -- We removed an entry, so we need to decrement i to land on the same
      -- position again next iteration.
      i = i - 1
    else
      seen[step.recipe.id] = true
    end
  end
end

--- Get the *first* recipe available for the given item. If the item (or ingredients) have multiple recipes, it will use the first and build a crafting plan from that. This method is faster than other methods, but breaks down if there is a loop.
---@param item integer The item id to get the recipe for.
---@param amount number The amount of the item to craft.
---@param max_depth number? The maximum depth to search for recipes. If set at 1, will only return the recipe for the given item. Higher values will give you recipes for items that are ingredients in the recipe for the given item. Be warned, if you set it too high and there are loops, you may have issues. Defaults to 1.
---@param recipe_selections table<integer, Recipe>? A recipe in this lookup table will be used if crafting the item requires one of the ingredients in the list. This is useful for items which have multiple crafting recipes, as you can override which recipe that ingredient will be made with. Any item that has multiple recipes without a recipe in this list will use the first recipe that can be grabbed.
---@param item_exclusions table<integer, true>? A dictionary containing any items that the user already has, and should not be included in the crafting plan.
---@return FinalizedCraftingPlan? plan The crafting plan for the given item, or nil if no recipe was found.
---@return string? error The error message if no recipe was found.
function RecipeHandler.get_first_recipe(item, amount, max_depth, recipe_selections, item_exclusions)
  expect(1, item, "number")
  expect(2, amount, "number")
  expect(3, max_depth, "number", "nil")
  expect(4, recipe_selections, "table", "nil")
  max_depth = max_depth or 1
  recipe_selections = recipe_selections or {}
  item_exclusions = item_exclusions or {}

  zero_recipe_graph()

  -- First, we need to find the recipe for the given item. This should also give
  -- us our node.
  local recipe_nodes = recipe_graph:find_nodes(function(n) return n.value.item == item end) --[[@as RecipeGraphNode[] ]]

  if #recipe_nodes == 0 then
    return nil, "No recipe found for item: " .. item
  end

  local recipe_node = recipe_nodes[1]

  local recipe_selection = recipe_selections[item]
  if recipe_selection then
    prints(0, "Recipe selection found for", item, ":", recipe_selection.result.id, "(", recipe_selection.id, ")")
    -- We need to use this recipe instead of the others.
    recipe_node = recipe_graph:find_node(function(n) return n.value.recipe.id == recipe_selection.id end) --[[@as RecipeGraphNode]]
  else
    prints(0, "No recipe selection found for", item)
  end

  if not recipe_node then
    -- All ingredients should have nodes by this point
    error(("Recipe node not found for %s. This is likely a bug, please report it and include your recipe list."):format(item))
  end

  -- And ensure we mark this recipe as selected, so future iterations will use
  -- this recipe.
  recipe_selections[item] = recipe_node.value.recipe

  -- Now, we step from the recipe node, into its ingredients, and calculate how
  -- many of each ingredient we need to craft the given amount of the item.
  -- Then for that ingredient's ingredients, and so on.
  ---@param node RecipeGraphNode The node to step from.
  ---@param depth number The current depth of the step.
  ---@param spaces integer The number of spaces to indent the debug output.
  local function step(node, depth, spaces)
    prints(spaces, "Stepping into", node.value.item)
    spaces = spaces + 2
    if depth <= 0 then
      prints(spaces, "Depth exceeded")
      return
    end

    local recipe = node.value.recipe

    if not recipe then
      -- This is a raw material, so we don't need to do anything.
      prints(spaces, "Raw material.")
      return
    end

    prints(spaces, "Needed:", node.value.needed)
    local old_crafts = node.value.crafts
    -- We need to craft the item this many times to get the amount we need.
    node.value.crafts = math.ceil(node.value.needed / recipe.result.amount)
    prints(spaces, "Crafts:", node.value.crafts)

    -- This is how many total will be made.
    node.value.output_count = node.value.crafts * recipe.result.amount
    prints(spaces, "Output count:", node.value.output_count)

    spaces = spaces + 2
    for _, ingredient in ipairs(recipe.ingredients) do
      local ingredient_nodes = recipe_graph:find_nodes(function(n) return n.value.item == ingredient.id end) --[[@as RecipeGraphNode[] ]]
      local ingredient_node = ingredient_nodes[1]

      -- Check if this ingredient has a recipe selection.
      local selection = recipe_selections[ingredient.id]
      if selection then
        prints(spaces, "Recipe selection found for", ingredient.id, ":", selection.result.id, "(", selection.id, ")")
        -- We need to use this recipe instead of the others.
        ingredient_node = recipe_graph:find_node(function(n) return n.value.recipe.id == selection.id end) --[[@as RecipeGraphNode]]
        prints(spaces, "Getting item id", ingredient_node.value.item, "from selection")
      else
        prints(spaces, "No recipe selection found for", ingredient.id)
        recipe_selections[ingredient.id] = ingredient_node.value.recipe
        prints(spaces, "Setting recipe selection for", ingredient.id, "to", ingredient_node.value.item, "(", ingredient_node.value.recipe and ingredient_node.value.recipe.id or "No recipe", ")")
        prints(spaces, "Getting item id", ingredient_node.value.item, "from node")
      end

      prints(spaces, "Looking at:", ingredient.id)

      if ingredient.id ~= ingredient_node.value.item then
        prints(spaces, "############################################### Ingredient id mismatch:", ingredient.id, ingredient_node.value.item)
      end

      if not ingredient_node then
        -- All ingredients should have nodes by this point
        error(("Ingredient node not found for %s. This is likely a bug, please report it and include your recipe list."):format(ingredient.id))
      end

      -- We need this many of the ingredient.
      prints(spaces, "Previous needed for", ingredient_node.value.item, ":", ingredient_node.value.needed)
      ingredient_node.value.needed = ingredient_node.value.needed + (ingredient.amount * (node.value.crafts - old_crafts))
      prints(spaces, "New needed for", ingredient_node.value.item, ":", ingredient_node.value.needed)

      if not item_exclusions[ingredient_node.value.item] then
        -- Now, we need to step into the ingredient's ingredients.
        step(ingredient_node, depth - 1, spaces)
      else
        prints(spaces, "Excluding costs for", ingredient_node.value.item)
      end
    end

  end

  -- Initialize the first node in the graph.
  recipe_node.value.needed = amount

  -- And start stepping through it.
  step(recipe_node, max_depth, 0)

  -- Now, we need to build the crafting plan from the graph.
  local crafting_plan = {
    item = item,
    output_count = 0,
    steps = {}
  } --[[@as CraftingPlan]]

  --- Step through the graph to build the crafting plan.
  ---@param node RecipeGraphNode The node to step from.
  ---@param depth number The current depth of the step.
  local function build_plan(node, depth)
    if depth <= 0 then
      return
    end

    local recipe = node.value.recipe

    if not recipe then
      -- This is a raw material, so we don't need to do anything.
      return
    end

    for _, ingredient in ipairs(recipe.ingredients) do
      local ingredient_nodes = recipe_graph:find_nodes(function(n) return n.value.item == ingredient.id end) --[[@as RecipeGraphNode]]
      local ingredient_node = ingredient_nodes[1]

      -- Check if this ingredient has a recipe selection.
      local selection = recipe_selections[ingredient.id]
      if selection then
        -- We need to use this recipe instead of the others.
        ingredient_node = recipe_graph:find_node(function(n) return n.value.recipe.id == selection.id end) --[[@as RecipeGraphNode]]
      end

      if not ingredient_node then
        -- All ingredients should have nodes by this point
        error(("Ingredient node not found for %s. This is likely a bug, please report it and include your recipe list."):format(ingredient.id))
      end

      if not item_exclusions[ingredient_node.value.item] then
        -- Now, we need to step into the ingredient's ingredients.
        build_plan(ingredient_node, depth - 1)
      end
    end

    -- Now that we've stepped through the ingredients, add this recipe to the
    -- crafting plan.
    table.insert(crafting_plan.steps, {
      item = node.value.item,
      output_count = node.value.output_count,
      needed = node.value.needed,
      crafts = node.value.crafts,
      recipe = recipe
    })
  end

  build_plan(recipe_node, max_depth)

  -- Final step: Remove duplicate entries from the crafting plan.
  clean_crafting_plan(crafting_plan)

  -- Finalize the crafting plan by adding raw material costs.
  crafting_plan.raw_material_cost = RecipeHandler.get_raw_material_cost(crafting_plan)

  if _DEBUG then
    prints(0, "Waiting for enter press")
    repeat local _, key = os.pullEvent("key") until key == keys.enter
  end

  return crafting_plan
end

--- Get as many recipes as possible for the given item.
---@deprecated This method is not actually deprecated, but I would like a warning to show when people use it. This method *does not work*, and will error immediately.
---@param item integer The item id to get the recipes for.
---@param amount number The amount of the item to craft.
---@param max_depth number? The maximum depth to search for recipes. If set at 1, will only return the recipe for the given item. Higher values will give you recipes for items that are ingredients in the recipes for the given item. Be warned, if you set it too high and there are loops, you may have issues. Defaults to 1.
---@param max_iterations number? The total maximum number of iterations to perform. For each depth decrement, this value will also decrement. If this value reaches 0, the function will stop searching for more recipes and cancel the current recipe it was building. Defaults to 100.
---@return FinalizedCraftingPlan[]? plans The crafting plans for the given item.
---@return string? error The error message if no recipe was found.
function RecipeHandler.get_all_recipes(item, amount, max_depth, max_iterations)
  expect(1, item, "number")
  expect(2, amount, "number")
  expect(3, max_depth, "number", "nil")
  expect(4, max_iterations, "number", "nil")
  max_depth = max_depth or 1
  max_iterations = max_iterations or 100

  --[[
    There are some major problems I do not know how to get around here.

    The main issue however, is that I am unsure how to deal with a recipe having
    two ingredients that have two different recipes. I can deal with a recipe
    that a single ingredient that has multiple recipes, but not two ingredients.

    My issue is that I am just not sure of how to implement the branching logic
    for this.

    For now, I will leave what I have here, but I will need to come back to this
    later.
  ]]

  error("Not yet working.", 2)

  ---@type CraftingPlan[]
  local crafting_plans = {}
  ---@type RecipeGraph[]
  local graphs = {}

  --- Used to keep track of what steps the current graph is on, so that later, when we build the crafting plans, we can know how to step down the graph.
  local step_lists = {}

  zero_recipe_graph()

  -- First, we need to find all possible recipes for our item. This should also
  -- give us the nodes for each recipe.
  local recipe_nodes = recipe_graph:find_nodes(function(n) return n.value.item == item end) --[[ @as RecipeGraphNode[] ]]
  if #recipe_nodes == 0 then
    return nil, "No recipe found for item: " .. item
  end

  for i = 1, #recipe_nodes do
    prints(0, "Recipe node", i, ":", recipe_nodes[i].value.item)
    prints(0, "Recipe node id:", recipe_nodes[i].value.recipe.id)
  end

  -- Now, we step from each recipe node, into its ingredients, and calculate how
  -- many of each ingredient we need to craft the given amount of the item.
  -- Then for that ingredient's ingredients, and so on.
  ---@param node RecipeGraphNode The node to step from.
  ---@param current_graph RecipeGraph The current graph we are stepping through.
  ---@param step_list table The list of steps for the current graph.
  ---@param depth number The current depth of the step.
  ---@param spaces integer The number of spaces to indent the debug output.
  ---@param only_ingredient_index integer? The index of the ingredient to ensure is used. Used when we split a graph into multiple graphs, so we don't get stuck in a loop
  ---@param only_ingredient_recipe_index integer? The index of the recipe to ensure is used. Used when we split a graph into multiple graphs, so we don't get stuck in a loop
  local function step(node, current_graph, step_list, depth, spaces, only_ingredient_index, only_ingredient_recipe_index)
    prints(spaces, "Stepping into", node.value.item)
    prints(spaces, "Only ingredient specified.")
    spaces = spaces + 2
    if depth <= 0 then
      prints(spaces, "Depth exceeded")
      return
    end

    local recipe = node.value.recipe

    if not recipe then
      -- This is a raw material, so we don't need to do anything.
      prints(spaces, "Raw material.")
      return
    end

    --[[
      Note for future me: I believe I can get around the issue of having to
      splitting the graph causing major issues by splitting right here, instead
      of doing it in the big main loop below.
      Branch off immediately, and I won't need to undo anything. I will,
      however, need to figure out how to handle those loops in the branches.
      But it should be a bit easier.
    ]]

    -- We need to craft the item this many times to get the amount we need.
    local old_crafts = node.value.crafts
    node.value.crafts = math.ceil(node.value.needed / recipe.result.amount)
    prints(spaces, "Crafts:", node.value.crafts)

    -- This is how many total will be made.
    node.value.output_count = node.value.crafts * recipe.result.amount
    prints(spaces, "Output count:", node.value.output_count)

    table.insert(step_list, node.value.recipe.id)
    prints(spaces, "Inserted:", node.value.recipe.id)

    for i, ingredient in ipairs(recipe.ingredients) do
      local ingredient_nodes = current_graph:find_nodes(function(n) return n.value.item == ingredient.id end) --[[ @as RecipeGraphNode[] ]]

      local n_nodes = #ingredient_nodes
      if n_nodes == 0 then
        -- All ingredients should have nodes by this point
        error(("Ingredient node not found for %s. This is likely a bug, please report it and include your recipe list."):format(ingredient.id))
      end

      -- for each ingredient node, split off a new graph and step through it.
      -- Unless there is only one, in which case we can just step through the
      -- current graph.

      prints(spaces, "Got", n_nodes, "ingredient node(s)")

      if i == only_ingredient_index then
        --using the current graph, step through.
        prints(spaces, "ONLY INGREDIENT INDEX:", only_ingredient_index)
        prints(spaces, "ONLY INGREDIENT RECIPE INDEX:", only_ingredient_recipe_index)

        -- Calculate ingredients...
        local current_node = ingredient_nodes[only_ingredient_recipe_index]
        prints(spaces, "Looking at child node:", current_node.value.item)

        -- We need this many of the ingredient.
        prints(spaces, "Old needed:", current_node.value.needed)
        current_node.value.needed = current_node.value.needed + (ingredient.amount * (node.value.crafts - old_crafts))
        prints(spaces, "Calculated child (", current_node.value.item , ") needed:", current_node.value.needed)

          -- Now, we need to step into the ingredient's ingredients.
        step(current_node, current_graph, step_list, depth - 1, spaces)
      else
        for j = 2, n_nodes do
          -- Clone the graph and insert it into the graph list
          local new_graph = current_graph:clone() --[[@as RecipeGraph]]
          graphs[#graphs + 1] = new_graph

          -- Grab the current node from the new graph
          local new_current_node = new_graph:find_node(function(n) return n.value.recipe.id == node.value.recipe.id end) --[[@as RecipeGraphNode]]
          new_current_node.value.crafts = old_crafts -- undo this as well
          new_current_node.value.output_count = old_crafts * recipe.result.amount -- and this

          -- Since we will be stepping through a new graph, we need to copy the
          -- current step list and pass that to the step function.

          -- a surface level copy should be fine, but we'll use deep copy here
          -- in case I change anything in the future.
          local new_step_list = util.deep_copy(step_list)
          step_lists[#step_lists + 1] = new_step_list

          new_step_list[#new_step_list] = nil -- remove the last entry, since we'll be stepping through a new graph pretending this iteration didn't happen.

          -- Now, let's go.
          prints(spaces, "###SPLITTING")
          step(new_current_node, new_graph, new_step_list, depth - 1, spaces + 10, i, j)
        end
        -- Then step through the first, using the current graph.

        -- Calculate ingredients...
        local current_node = ingredient_nodes[1]
        prints(spaces, "Looking at child node:", current_node.value.item)

        -- We need this many of the ingredient.
        current_node.value.needed = current_node.value.needed + (ingredient.amount * (node.value.crafts - old_crafts))
        prints(spaces, "Calculated child (", current_node.value.item , ") needed:", current_node.value.needed)

          -- Now, we need to step into the ingredient's ingredients.
        step(current_node, current_graph, step_list, depth - 1, spaces)
      end
    end
  end

  -- Initialize the first nodes in the graph.
  for i = 1, #recipe_nodes do
    local recipe_node = recipe_nodes[i]
    recipe_node.value.needed = amount
    graphs[i] = recipe_graph:clone() --[[@as RecipeGraph]]
    recipe_node.value.needed = 0
  end

  -- Step through each of the initial nodes.
  local n_nodes = #recipe_nodes
  for i = 1, n_nodes do
    local step_list = {}
    step_lists[i] = step_list

    local node = graphs[i]:find_node(function(n) return n.value.recipe.id == recipe_nodes[i].value.recipe.id end) --[[@as RecipeGraphNode]]

    prints(0, "Starting through", node.value.item)
    prints(0, "Random id:", node.value.recipe.id)

    step(
      node,
      graphs[i],
      step_list,
      max_depth,
      0
    )
  end

  -- Now, we need to build the crafting plans from the graphs. There may be more
  -- graphs than what we started with if other ingredients have multiple
  -- recipes.

  --- Step through the given graph to build the crafting plan.
  ---@param crafting_plan CraftingPlan The crafting plan to build.
  ---@param current_graph RecipeGraph The current graph we are stepping through.
  ---@param step_list table The list of steps followed for the current graph.
  ---@param step_i integer The current step in the step list.
  ---@param depth number The current depth of the step.
  local function build_plan(crafting_plan, current_graph, step_list, step_i, depth)
    -- Get the current step's node.
    local ingredient_node = current_graph:find_node(function(n)
      return n.value.recipe and n.value.recipe.id == step_list[step_i]
    end) --[[@as RecipeGraphNode]]
    if ingredient_node then
      prints(0, "Found ingredient node")
      prints(0, "Building plan for", ingredient_node.value.item, "with", #step_list, "steps")
      local recipe = ingredient_node.value.recipe

      if depth <= 0 then
        prints(0, "Depth exceeded")
        return
      end
      if step_i > #step_list then
        prints(0, "Step index exceeded")
        return
      end

      if not recipe then
        -- This is a raw material, so we don't need to do anything.
        return
      end

      -- Descend into the next steps first so we build the plan from the bottom up.
      build_plan(crafting_plan, current_graph, step_list, step_i + 1, depth - 1)


      if not ingredient_node then
        -- All ingredients should have nodes by this point
        error(("Ingredient node not found for %s. This is likely a bug, please report it and include your recipe list."):format(ingredient_node.value.id))
      end

      -- Now that we've stepped through the ingredients, add this recipe to the
      -- crafting plan.
      table.insert(crafting_plan.steps, {
        item = ingredient_node.value.item,
        output_count = ingredient_node.value.output_count,
        needed = ingredient_node.value.needed,
        crafts = ingredient_node.value.crafts,
        recipe = recipe
      })
    else
      prints(2, "Didn't find ingredient node.")
    end
  end

  -- Now, actually build the crafting plans.
  for i = 1, #graphs do
    local crafting_plan = {
      item = item,
      output_count = 0,
      steps = {}
    } --[[@as CraftingPlan]]

    build_plan(
      crafting_plan,
      graphs[i],
      step_lists[i],
      1,
      max_depth
    )

    -- Final step: Remove duplicate entries from the crafting plan.
    clean_crafting_plan(crafting_plan)

    -- Insert the new plan into the list.
    crafting_plans[#crafting_plans + 1] = crafting_plan

    --[[ ignore this for now
    max_iterations = max_iterations - 1
    if max_iterations <= 0 then
      break
    end
    ]]
  end

  -- Semi final stage: Remove plans that use two different methods to make the
  -- same item.
  for i = #crafting_plans, 1, -1 do
    local seen = {}
    local plan = crafting_plans[i]
    for j = 1, #plan.steps do
      local step = plan.steps[j]
      if seen[step.item] then
        -- This plan uses two different methods to make the same item, so
        -- remove it.
        table.remove(crafting_plans, i)
        break
      else
        seen[step.item] = true
      end
    end
  end

  -- Absolute final state: Sort the crafting plans by the least raw material
  -- cost

  -- First, we need to get the raw material cost for each plan.
  ---@cast crafting_plans FinalizedCraftingPlan[]
  for i = 1, #crafting_plans do
    local plan = crafting_plans[i]
    plan.raw_material_cost = RecipeHandler.get_raw_material_cost(plan)
  end

  return crafting_plans
end

--- Create a new recipe for the given item, but do not insert it into the recipe list.
---@param item_name string The name of the item to create the recipe for.
---@param output_count number The amount of the item that are outputted by the recipe.
---@param ingredients RecipeIngredient[] The ingredients required to craft the item.
---@param machine integer? The machine used to craft the item. Defaults to "crafting table".
---@param is_fluid boolean? Whether or not the item is a fluid. Defaults to false.
---@param is_preferred boolean? Whether or not the recipe is preferred. Defaults to false.
---@param previous_name string? The previous name of the item, if editing an existing recipe.
---@return Recipe recipe The recipe created.
function RecipeHandler.create_recipe_object(item_name, output_count, ingredients, machine, is_fluid, is_preferred, previous_name)
  -- Check items_common for the item id. If it doesn't exist, add it.
  local item_id = items_common.get_item_id(item_name)

  if previous_name and not item_id then
    -- The item id doesn't exist, but we have a previous name. This means the
    -- item was renamed, so we need to get the id from the previous name.
    item_id = items_common.get_item_id(previous_name)

    if not item_id then
      -- The previous name doesn't exist, this is an error.
      error(("Previous name %s does not exist."):format(previous_name), 2)
    end

    -- We need to update the item name in items_common.
    items_common.edit_item(item_id, item_name)
  elseif not previous_name and not item_id then
    -- The item id doesn't exist, and we don't have a previous name. This means
    -- the item is new, so we need to add it.
    item_id = items_common.add_item(item_name)
  end
  ---@cast item_id integer It can no longer be nil after the above.

  ---@type Recipe
  return {
    result = {
      id = item_id,
      amount = output_count,
      fluid = not not is_fluid
    },
    ingredients = ingredients,
    machine = machine or 0,
    enabled = true,
    preferred = not not is_preferred,
    id = generate_unique_id()
  }
end

--- Create a new recipe for the given item.
---@param item_name string The item name to create the recipe for.
---@param output_count number The amount of the item that are outputted by the recipe.
---@param ingredients RecipeIngredient[] The ingredients required to craft the item.
---@param machine integer? The machine used to craft the item. Defaults to "crafting table".
---@param is_fluid boolean? Whether or not the item is a fluid. Defaults to false.
---@return Recipe recipe The recipe created.
function RecipeHandler.create_recipe(item_name, output_count, ingredients, machine, is_fluid)
  -- Check items_common for the item id. If it doesn't exist, add it.
  local item_id = items_common.get_item_id(item_name)
  if not item_id then
    item_id = items_common.add_item(item_name)
  end

  ---@type Recipe
  local recipe = RecipeHandler.create_recipe_object(item_name, output_count, ingredients, machine, is_fluid)

  table.insert(recipes, recipe)
  lookup[item_id] = lookup[item_id] or {}
  table.insert(lookup[item_id], recipe)

  return recipe
end

--- Get a text representation of the given crafting plan.
---@param plan CraftingPlan The crafting plan to get the text representation of.
---@param plan_number number? The number of the plan. Defaults to 1.
---@return string[] text The text representation of the crafting plan, where each line represents a step in the plan.
function RecipeHandler.get_plan_as_text(plan, plan_number)
  local textual = {} ---@type string[]

  -- Get the lookup of item ids to names
  local item_lookup = items_common.get_items()

  table.insert(textual, "===============")
  table.insert(textual, ("Crafting plan #%d raw material cost:"):format(plan_number or 1))

  local raw_materials = {}
  for item_name, amount in pairs(RecipeHandler.get_raw_material_cost(plan)) do
    table.insert(raw_materials, {item_name, amount})
  end

  table.sort(raw_materials, function(a, b) return a[1] < b[1] end)

  for _, data in ipairs(raw_materials) do
    table.insert(textual, ("  %s: %d"):format(item_lookup[data[1]] and item_lookup[data[1]].name or "Unknown Item", data[2]))
  end
  table.insert(textual, "===============")

  local line_formatter = "Use the %s to make %d %s%s from %s."
  local ingredient_formatter = "%d %s%s%s"

  for _, step in ipairs(plan.steps) do
    local ingredients = step.recipe.ingredients
    local ingredient_textual = {} ---@type string[]
    for i = 1, #ingredients do
      local ingredient = ingredients[i]
      if i ~= #ingredients and i ~= 1 then
        table.insert(ingredient_textual, ", ")
      elseif i ~= 1 then
        table.insert(ingredient_textual, ", and ")
      end
      table.insert(ingredient_textual, ingredient_formatter:format(
        ingredient.amount * step.crafts,
        item_lookup[ingredient.id] and item_lookup[ingredient.id].name or "Unknown Item",
        ingredient.amount * step.crafts > 1 and "s" or "",
        ingredient.fluid and " (fluid)" or ""
      ))
    end

    if not machines_common.machines[step.recipe.machine] then
      error(("Machine with id %s not found."):format(step.recipe.machine))
    end

    local line = line_formatter:format(
      machines_common.machines[step.recipe.machine] and machines_common.machines[step.recipe.machine].name or "Unknown Machine",
      step.output_count,
      item_lookup[step.recipe.result.id] and item_lookup[step.recipe.result.id].name or "Unknown Item",
      step.output_count > 1 and "s" or "",
      table.concat(ingredient_textual)
    )

    table.insert(textual, line)
  end

  return textual
end

--- Get the raw material cost (any material which does not have a crafting recipe is considered "raw") of the given crafting plan.
---@param plan CraftingPlan The crafting plan to get the raw material cost of.
---@return MaterialCost cost The raw material cost of the crafting plan.
function RecipeHandler.get_raw_material_cost(plan)
  local cost = {} ---@type MaterialCost

  -- Get the list of all item data
  local item_data = items_common.get_items()

  for _, step in ipairs(plan.steps) do
    for _, ingredient in ipairs(step.recipe.ingredients) do
      if not lookup[ingredient.id] then

        if not item_data[ingredient.id] then
          error(("Item with id %d not found."):format(ingredient.id))
        end

        if not item_data[ingredient.id].ignored then
          -- This is a raw material and is not ignored, so add it to the cost.
          if not cost[ingredient.id] then
            cost[ingredient.id] = 0
          end

          cost[ingredient.id] = cost[ingredient.id] + (ingredient.amount * step.crafts)
        end
      end
    end
  end

  return cost
end

--- Get the recipes for the given item.
---@param item integer The item to get the recipes for.
---@return Recipe[]? recipes The recipes for the given item. Nil if nothing.
function RecipeHandler.get_recipes(item)
  return util.deep_copy(lookup[item])
end

--- Get the lookup table of recipes
---@return RecipeLookup lookup The lookup table of recipes.
function RecipeHandler.get_lookup()
  return util.deep_copy(lookup)
end

--- Get a list of all the items that have recipes.
---@return integer[] items The list of items that have recipes.
function RecipeHandler.get_items()
  local items = {} ---@type integer[]

  for item_id in pairs(lookup) do
    table.insert(items, item_id)
  end

  return items
end

--- Get a combined list of all items that have recipes and all items that are ingredients in recipes.
---@return integer[] items The list of items that have recipes or are ingredients in recipes.
function RecipeHandler.get_all_items()
  local items = {} ---@type integer[]

  local deduplicate = {} ---@type table<integer, boolean>

  for item_id in pairs(lookup) do
    table.insert(items, item_id)
    deduplicate[item_id] = true
  end

  for _, recipe in ipairs(recipes) do
    for _, ingredient in ipairs(recipe.ingredients) do
      if not deduplicate[ingredient.id] then
        table.insert(items, ingredient.id)
        deduplicate[ingredient.id] = true
      end
    end
  end

  return items
end

--- Get a list of uncraftable items (items that do not have a recipe).
---@return integer[] items The list of items that do not have a recipe.
function RecipeHandler.get_uncraftable_items()
  local items = {} ---@type integer[]

  for item_id in pairs(items_common.get_items()) do
    if not lookup[item_id] then
      table.insert(items, item_id)
    end
  end

  return items
end

-- Get a list of items that are needed to craft the given item.
---@param plan CraftingPlan The crafting plan to get the items for.
---@return integer[] items The list of items that are needed to craft the given item.
function RecipeHandler.get_needed_items(plan)
  local items = {} ---@type integer[]
  local item_set = {} ---@type table<integer, boolean>

  for _, step in ipairs(plan.steps) do
    -- Only add it if we haven't already added it, and if it's not a raw material.
    if not item_set[step.item] and lookup[step.item] then
      table.insert(items, step.item)
      item_set[step.item] = true
    end

    for _, ingredient in ipairs(step.recipe.ingredients) do
      -- Only add it if we haven't already added it, and if it's not a raw material.
      if not item_set[ingredient.id] and lookup[ingredient.id] then
        table.insert(items, ingredient.id)
        item_set[ingredient.id] = true
      end
    end
  end

  return items
end

--- Get a recipe via its id.
---@param id number The id of the recipe to get.
---@return Recipe? recipe The recipe, or nil if not found.
function RecipeHandler.get_recipe(id)
  for i = 1, #recipes do
    local recipe = recipes[i]
    if recipe.id == id then
      return util.deep_copy(recipe)
    end
  end

  return nil
end

--- Edit data for a given recipe.
---@param id number The id of the recipe to edit.
---@param data table The new data for the recipe, ID will be ignored, so you can use RecipeHandler.create_recipe_object to create the data. Anything missing will remain unchanged.
function RecipeHandler.edit_recipe(id, data)
  for i = 1, #recipes do
    local recipe = recipes[i]
    if recipe.id == id then
      local preferred = recipe.preferred
      if data.preferred ~= nil then -- my brain isnt braining right now so this is an if statement instead of an or
        preferred = data.preferred
      end

      recipe.result = data.result or recipe.result
      recipe.ingredients = data.ingredients or recipe.ingredients
      recipe.machine = data.machine or recipe.machine
      recipe.enabled = data.enabled or recipe.enabled
      recipe.preferred = preferred
      return
    end
  end

  error(("No recipe found with id %d"):format(id), 2)
end

--- Remove a recipe by its id.
---@param id number The id of the recipe to remove.
function RecipeHandler.remove_recipe(id)
  local s1, s2 = false, false
  -- Find the recipe in the main list and remove it.
  for i = 1, #recipes do
    local recipe = recipes[i]
    if recipe.id == id then
      table.remove(recipes, i)
      s1 = true
      break
    end
  end

  -- Find the recipe in the lookup and remove it.
  for _, item_recipes in pairs(lookup) do
    for i = 1, #item_recipes do
      local recipe = item_recipes[i]
      if recipe.id == id then
        table.remove(item_recipes, i)
        s2 = true
        return
      end
    end
  end

  error(("No recipe found for item with id %d (%s|%s)"):format(id, s1, s2), 2)
end

--- Copy the save file to a backup.
function RecipeHandler.backup_save()
  file_helper:write(RecipeHandler.BACKUP_FILE, file_helper:get_all(RecipeHandler.SAVE_FILE))
end

return RecipeHandler
