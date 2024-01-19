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
local file_helper = require "file_helper"
local graph = require "graph"
local shallow_serialize = require "graph.shallow_serialize" 

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
---@field machine string The machine used to craft the item. Defaults to "crafting table".
---@field enabled boolean Whether or not the recipe is enabled.

---@class RecipeIngredient A single ingredient in the recipe.
---@field name string The name of the ingredient.
---@field amount number The amount of the ingredient.
---@field fluid boolean Whether or not the ingredient is a fluid.

---@class FluidRecipeIngredient : RecipeIngredient A single ingredient in the recipe (fluid).
---@field amount number The amount of the ingredient, in millibuckets.
---@field fluid true Whether or not the ingredient is a fluid.

---@alias RecipeLookup table<string, Recipe[]>

---@class CraftingPlan A plan containing all the steps, in order, to craft the given item.
---@field item string The item to craft.
---@field output_count number The amount of items that will be outputted.
---@field steps CraftingPlanStep[] The steps to craft the item.

---@class CraftingPlanStep A single step in the crafting plan.
---@field item string The item to craft.
---@field output_count number The amount of items that will be outputted.
---@field needed number The amount of the item crafted that are needed in future steps.
---@field crafts number The amount of times to repeat the crafting process.
---@field recipe Recipe? The recipe to use to craft the item, if the item can be crafted.

---@class MultiCraftPlanStep A single step in a crafting plan, that can have multiple recipes.
---@field item string The item to craft.
---@field output_count number The amount of items that will be outputted.
---@field needed number The amount of the item crafted that are needed in future steps.
---@field crafts number The amount of times to repeat the crafting process.
---@field recipes Recipe[] The recipes that can be used to craft the item.

---@alias MaterialCost table<string, number>

--------------------------------------------------------------------------------
--                  End Lua Language Server Type Definitions                  --
--------------------------------------------------------------------------------

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
        name = recipe.result.name,
        amount = recipe.result.amount,
        fluid = recipe.result.fluid
      },
      ingredients = {}
    }

    if recipe.enabled then
      small_recipe.enabled = true
    end

    if recipe.machine == "crafting table" then
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
        name = ingredient.name,
        amount = ingredient.amount,
        fluid = ingredient.fluid
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

--- Deep copy a value
---@generic T
---@param t T The value to copy.
---@return T copy The copy of the value.
local function deep_copy(t)
  if type(t) ~= "table" then
    return t
  end

  local copy = {}

  for k, v in pairs(t) do
    copy[k] = deep_copy(v)
  end

  return copy
end

---@class RecipeHandler
local RecipeHandler = {}

--- Load the recipes from the given file. WARNING: This wipes the currently loaded recipe list first, then loads the recipes.
---@param filename string The file to load the recipes from.
function RecipeHandler.load(filename)
  recipes = {} ---@type RecipeList
  local lines = file_helper.get_lines(filename)

  for i = 1, lines.n do
    local line = lines[i]
    local recipe = RecipeHandler.parse_recipe(line)

    if recipe then
      table.insert(recipes, recipe)
    else
      printError(("Failed to parse recipe on line %d: %s"):format(i, line))
    end

    if i % 1000 == 0 then
      -- This program really shouldn't be used with huuuge recipe lists,
      -- but we'll support it anyways.
      print(("Loaded %d recipes"):format(i))
      os.queueEvent("recipe_load_progress", i)
      os.pullEvent("recipe_load_progress")
    end
  end

  RecipeHandler.build_lookup()
end

--- Parse a recipe from a string.
---@param line string The string to parse the recipe from.
---@return Recipe? recipe The recipe parsed from the string.
function RecipeHandler.parse_recipe(line)
  local recipe = textutils.unserialize(line)

  if not recipe then
    return nil
  end

  if not recipe.result then
    return nil
  end

  if not recipe.result.name then
    return nil
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
    return nil
  end

  if not recipe.machine then
    recipe.machine = "crafting table"
  end

  for i = 1, #recipe.ingredients do
    local ingredient = recipe.ingredients[i]

    if not ingredient.name then
      return nil
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

--- Parse a json style recipe from a string.
---@param json string The string to parse the recipe from.
---@return Recipe? recipe The recipe parsed from the string.
function RecipeHandler.parse_json_recipe(json)
  ---@FIXME implement this
  error("Not yet implemented.", 2)
  return {}
end

--- Insert a recipe into the recipe list.
---@param recipe Recipe The recipe to insert.
function RecipeHandler.insert(recipe)
  ---@FIXME confirm the recipe is valid
  table.insert(recipes, recipe)
end

--- Save the recipes to the given file.
---@param filename string The file to save the recipes to.
function RecipeHandler.save(filename)
  local lines = {}

  for i = 1, #recipes do
    local recipe = recipes[i]
    local line = textutils.serialize(recipe, { compact = true })

    table.insert(lines, line)
  end

  file_helper.write(filename, table.concat(lines, "\n"))
end

--- Build/rebuild the recipes list into a lookup table of output items (keys) to a list of recipes (values).
local function build_lookup()
  lookup = {} ---@type RecipeLookup

  for i = 1, #recipes do
    local recipe = recipes[i]

    if recipe.enabled then
      if not lookup[recipe.result.name] then
        lookup[recipe.result.name] = {}
      end

      table.insert(lookup[recipe.result.name], recipe)
    end
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
  for item_name, item_recipes in pairs(lookup) do
    for i = 1, #item_recipes do
      local recipe = item_recipes[i]
      recipe_graph:add_node({
        item = item_name,
        recipe = deep_copy(recipe),
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
        local ingredient_name = ingredient.name
        local ingredient_nodes = recipe_graph:find_nodes(function(n) return n.value.item == ingredient_name end) --[[ @as RecipeGraphNode[] ]]

        if #ingredient_nodes == 0 then
          -- Ingredient doesn't have a recipe, create a node for it.
          local new_node = recipe_graph:add_node({
            item = ingredient_name,
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
---@param plan CraftingPlan The crafting plan to clean up.
local function clean_crafting_plan(plan)
  local seen = {}

  local i = 0
  while i <= #plan.steps do
    i = i + 1

    local step = plan.steps[i]
    if not step then break end

    if seen[step.item] then
      table.remove(plan.steps, i)

      -- We removed an entry, so we need to decrement i to land on the same
      -- position again next iteration.
      i = i - 1
    else
      seen[step.item] = true
    end
  end
end

--- Get the *first* recipe available for the given item. If the item (or ingredients) have multiple recipes, it will use the first and build a crafting plan from that. This method is faster than other methods, but breaks down if there is a loop.
---@param item string The item to get the recipe for.
---@param amount number The amount of the item to craft.
---@param max_depth number? The maximum depth to search for recipes. If set at 1, will only return the recipe for the given item. Higher values will give you recipes for items that are ingredients in the recipe for the given item. Be warned, if you set it too high and there are loops, you may have issues. Defaults to 1.
---@return CraftingPlan? plan The crafting plan for the given item, or nil if no recipe was found.
---@return string? error The error message if no recipe was found.
function RecipeHandler.get_first_recipe(item, amount, max_depth)
  expect(1, item, "string")
  expect(2, amount, "number")
  expect(3, max_depth, "number", "nil")
  max_depth = max_depth or 1

  zero_recipe_graph()

  local crafting_plan = {
    item = item,
    output_count = 0,
    steps = {}
  } --[[@as CraftingPlan]]

  -- First, we need to find the recipe for the given item. This should also give
  -- us our node.
  local recipe_node = recipe_graph:find_node(function(n) return n.value.item == item end) --[[@as RecipeGraphNode]]

  if not recipe_node then
    return nil, "No recipe found for item: " .. item
  end

  -- Now, we step from the recipe node, into its ingredients, and calculate how
  -- many of each ingredient we need to craft the given amount of the item.
  -- Then for that ingredient's ingredients, and so on.
  ---@param node RecipeGraphNode The node to step from.
  ---@param depth number The current depth of the step.
  local function step(node, depth)
    if depth <= 0 then
      return
    end

    local recipe = node.value.recipe

    if not recipe then
      -- This is a raw material, so we don't need to do anything.
      return
    end

    -- We need to craft the item this many times to get the amount we need.
    node.value.crafts = math.ceil(node.value.needed / recipe.result.amount)

    -- This is how many total will be made.
    node.value.output_count = node.value.crafts * recipe.result.amount

    for _, ingredient in ipairs(recipe.ingredients) do
      local ingredient_node = recipe_graph:find_node(function(n) return n.value.item == ingredient.name end) --[[@as RecipeGraphNode]]

      if not ingredient_node then
        -- All ingredients should have nodes by this point
        error(("Ingredient node not found for %s. This is likely a bug, please report it and include your recipe list."):format(ingredient.name))
      end

      -- We need this many of the ingredient.
      ingredient_node.value.needed = ingredient_node.value.needed + (ingredient.amount * node.value.crafts)

      -- Now, we need to step into the ingredient's ingredients.
      step(ingredient_node, depth - 1)
    end

  end

  -- Initialize the first node in the graph.
  recipe_node.value.needed = amount

  -- And start stepping through it.
  step(recipe_node, max_depth)

  -- Now, we need to build the crafting plan from the graph.
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
      local ingredient_node = recipe_graph:find_node(function(n) return n.value.item == ingredient.name end) --[[@as RecipeGraphNode]]

      if not ingredient_node then
        -- All ingredients should have nodes by this point
        error(("Ingredient node not found for %s. This is likely a bug, please report it and include your recipe list."):format(ingredient.name))
      end

      -- Now, we need to step into the ingredient's ingredients.
      build_plan(ingredient_node, depth - 1)
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

  return crafting_plan
end

--- Get as many recipes as possible for the given item.
---@param item string The item to get the recipes for.
---@param amount number The amount of the item to craft.
---@param max_depth number? The maximum depth to search for recipes. If set at 1, will only return the recipe for the given item. Higher values will give you recipes for items that are ingredients in the recipes for the given item. Be warned, if you set it too high and there are loops, you may have issues. Defaults to 1.
---@param max_iterations number? The total maximum number of iterations to perform. For each depth decrement, this value will also decrement. If this value reaches 0, the function will stop searching for more recipes and cancel the current recipe it was building. Defaults to 100.
---@return CraftingPlan[]? plans The crafting plans for the given item.
---@return string? error The error message if no recipe was found.
function RecipeHandler.get_all_recipes(item, amount, max_depth, max_iterations)
  expect(1, item, "string")
  expect(2, amount, "number")
  expect(3, max_depth, "number", "nil")
  expect(4, max_iterations, "number", "nil")
  max_depth = max_depth or 1
  max_iterations = max_iterations or 100

  ---@type CraftingPlan[]
  local crafting_plans = {}

  return crafting_plans
end

--- Create a new recipe for the given item.
---@param item string The item to create the recipe for.
---@param output_count number The amount of the item that are outputted by the recipe.
---@param ingredients RecipeIngredient[] The ingredients required to craft the item.
---@param machine string? The machine used to craft the item. Defaults to "crafting table".
---@return Recipe recipe The recipe created.
function RecipeHandler.create_recipe(item, output_count, ingredients, machine)
  ---@type Recipe
  local recipe = {
    result = {
      name = item,
      amount = output_count,
      fluid = false
    },
    ingredients = ingredients,
    machine = machine or "crafting table",
    enabled = true
  }

  table.insert(recipes, recipe)

  return recipe
end

--- Get a text representation of the given crafting plan.
---@param plan CraftingPlan The crafting plan to get the text representation of.
---@param plan_number number? The number of the plan. Defaults to 1.
---@return string[] text The text representation of the crafting plan, where each line represents a step in the plan.
function RecipeHandler.get_plan_as_text(plan, plan_number)
  local textual = {} ---@type string[]

  table.insert(textual, "===============")
  table.insert(textual, ("Crafting plan #%d raw material cost:"):format(plan_number or 1))
  for item_name, amount in pairs(RecipeHandler.get_raw_material_cost(plan)) do
    table.insert(textual, ("  %s: %d"):format(item_name, amount))
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
        ingredient.name,
        ingredient.amount * step.crafts > 1 and "s" or "",
        ingredient.fluid and " (fluid)" or ""
      ))
    end

    local line = line_formatter:format(
      step.recipe.machine,
      step.output_count,
      step.recipe.result.name,
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

  for _, step in ipairs(plan.steps) do
    for _, ingredient in ipairs(step.recipe.ingredients) do
      if not lookup[ingredient.name] then
        -- This is a raw material, so add it to the cost.
        if not cost[ingredient.name] then
          cost[ingredient.name] = 0
        end

        cost[ingredient.name] = cost[ingredient.name] + (ingredient.amount * step.crafts)
      end
    end
  end

  return cost
end

return RecipeHandler
