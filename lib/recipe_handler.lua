--- The RecipeHandler class is used to manage the crafting recipes given to the
--- program.

local expect = require "cc.expect".expect
local file_helper = require "file_helper"
local graph = require "graph"

--------------------------------------------------------------------------------
--                    Lua Language Server Type Definitions                    --
--------------------------------------------------------------------------------

---@class RecipeGraph : Graph
---@field root RecipeGraphNode The root node of the graph.
---@field nodes RecipeGraphNode[] A list of all nodes in the graph.

---@class RecipeGraphNode : GraphNode
---@field value CraftingPlanStep The currently planned recipe for the node.
---@field connections RecipeGraphNode[] The nodes connected to this node.

---@alias RecipeList Recipe[]

---@class Recipe A single crafting recipe.
---@field result RecipeIngredient The resultant item.
---@field ingredients RecipeIngredient[] The ingredients required to craft the item.
---@field machine string The machine used to craft the item. Defaults to "crafting table".

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
    local line = textutils.serialize(recipe, {compact = true})

    table.insert(lines, line)
  end

  file_helper.write(filename, table.concat(lines, "\n"))
end

--- Build the recipes list into a lookup table of output items (keys) to a list of recipes (values). This is automatically done when loading recipes from a file.
function RecipeHandler.build_lookup()
  lookup = {} ---@type RecipeLookup

  for i = 1, #recipes do
    local recipe = recipes[i]

    if not lookup[recipe.result.name] then
      lookup[recipe.result.name] = {}
    end

    table.insert(lookup[recipe.result.name], recipe)
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

  local recipe_graph, err = RecipeHandler.build_recipe_graph(item) 

  if not recipe_graph then
    return nil, err
  end

  local root = recipe_graph.root

  if not root then
    return nil, "No root node in crafting graph. Something really weird has happened if you're getting this error."
  end

  recipe_graph.root.value.needed = amount
  recipe_graph.root.value.crafts = math.ceil(amount / recipe_graph.root.value.recipe.result.amount)
  recipe_graph.root.value.output_count = recipe_graph.root.value.recipe.result.amount * recipe_graph.root.value.crafts

  -- Now, starting from the root node (the item we want to craft), we need to
  -- calculate the needed amount of each ingredient. We should not just SET the
  -- value of the ingredient, but we should instead increment it. This is
  -- because we may have multiple recipes that use the same ingredient, and we
  -- need to know how much of that ingredient we need in total.

  --- Calculate the needed amount of ingredients required to craft the given item.
  ---@param node RecipeGraphNode The node to calculate.
  local function calculate_needed(node)
    local needed = node.value.needed
    local crafts = node.value.crafts

    if node.value.recipe then
      for i = 1, #node.value.recipe.ingredients do
        local ingredient = node.value.recipe.ingredients[i]
        local ingredient_name = ingredient.name
        local ingredient_amount = ingredient.amount
        local ingredient_node = recipe_graph:find_node(function(n) return n.value.item == ingredient_name end) --[[@as RecipeGraphNode?]]

        if not ingredient_node then
          -- By this point, a node should have been made for ALL ingredients.
          -- If we get here, something has gone wrong.
          return nil, ("No node found for ingredient '%s'"):format(ingredient_name)
        end

        -- Add the amount of the ingredient needed to the node.
        ingredient_node.value.needed = ingredient_node.value.needed + (ingredient_amount * crafts)

        if ingredient_node.value.recipe then
          -- Recalculate the amount of crafts needed to craft that many items.
          ingredient_node.value.crafts = math.ceil(ingredient_node.value.needed / ingredient_node.value.recipe.result.amount)
          -- Recalculate the total amount of items that will be outputted.
          ingredient_node.value.output_count = ingredient_node.value.recipe.result.amount * ingredient_node.value.crafts
        end
      end
    end
  end

  -- now, starting from the root, "climb down" the graph and calculate the
  -- needed amount of each ingredient.

  -- While we're at it, we should be able to build the full CraftingPlan from
  -- this graph. Recursively, we can build the plan from the bottom up.

  ---@type CraftingPlan
  local crafting_plan = {
    item = root.value.item,
    output_count = root.value.output_count,
    steps = {}
  }

  --- Build the crafting plan from the given node.
  ---@param node RecipeGraphNode The node to start from.
  ---@param current_depth number The current depth of the node.
  local function climb_down(node, current_depth)
    if current_depth == 0 then
      return
    end

    calculate_needed(node)

    if not node.value.recipe then
      -- This is an ingredient that we don't have a recipe for, so we can't
      -- build a crafting plan for it. We'll just skip it.
      return
    end

    for i = 1, #node.value.recipe.ingredients do
      local ingredient = node.value.recipe.ingredients[i]
      local ingredient_name = ingredient.name
      local ingredient_node = recipe_graph:find_node(function(n) return n.value.item == ingredient_name end) --[[@as RecipeGraphNode?]]

      if not ingredient_node then
        -- By this point, a node should have been made for ALL ingredients.
        -- If we get here, something has gone wrong.
        return nil, ("No node found for ingredient '%s'"):format(ingredient_name)
      end

      climb_down(ingredient_node, current_depth - 1)
    end

    -- Add to the current crafting plan
    local step = {
      item = node.value.item,
      output_count = node.value.output_count,
      needed = node.value.needed,
      crafts = node.value.crafts,
      recipe = node.value.recipe
    } --[[@as CraftingPlanStep]]

    table.insert(crafting_plan.steps, step)
  end

  climb_down(root, max_depth or 1)

  -- Final step: Remove duplicate entries.

  local seen = {}

  local i = 0
  while i <= #crafting_plan.steps do
    i = i + 1

    local step = crafting_plan.steps[i]
    if not step then break end

    if seen[step.item] then
      table.remove(crafting_plan.steps, i)

      -- We removed an entry, so we need to decrement i to land on the same
      -- position again next iteration.
      i = i - 1
    else
      seen[step.item] = true
    end
  end

  return crafting_plan
end

--- Build a recipe graph for the given item.
--- @param item string The item to build the recipe graph for.
---@return RecipeGraph? crafting_graph The recipe graph for the given item.
---@return string? error The error message if no recipe was found.
function RecipeHandler.build_recipe_graph(item)
  if not lookup[item] then
    return nil, ("No recipe entry for item '%s'"):format(item)
  end

  local recipe = lookup[item][1]

  if not recipe then
    return nil, ("No recipe listed for item '%s'"):format(item)
  end

  -- Build a graph of the recipes.
  local root_recipe = deep_copy(recipe) --[[@as Recipe]]
  local root_step = {
    item = root_recipe.result.name,
    output_count = 0,
    needed = 0,
    crafts = 0,
    recipe = root_recipe
  } --[[@as CraftingPlanStep]]
  -- We start with all values at zero because we don't know how many of the item
  -- we need yet. We'll calculate that later.

  local crafting_graph = graph.new(root_step) --[[@as RecipeGraph]]
  local root = crafting_graph.root

  --- Build the graph
  ---@param node RecipeGraphNode The node to build the graph from.
  local function build_graph(node)
    for i = 1, #node.value.recipe.ingredients do
      local ingredient = node.value.recipe.ingredients[i]
      local ingredient_name = ingredient.name

      if lookup[ingredient_name] then
        local ingredient_recipes = lookup[ingredient_name]

        for j = 1, #ingredient_recipes do
          local ingredient_recipe = ingredient_recipes[j]
          local ingredient_node = crafting_graph:find_node(function(n) return n.value.item == ingredient_name end) --[[@as RecipeGraphNode?]]
          if not ingredient_node then
            -- We haven't added this recipe to the graph yet, so add it.
            local cloned_recipe = deep_copy(ingredient_recipe) --[[@as Recipe]]
            local ingredient_step = {
              item = cloned_recipe.result.name,
              output_count = 0,
              needed = 0,
              crafts = 0,
              recipe = cloned_recipe
            } --[[@as CraftingPlanStep]]
            -- We start with all values at zero because we don't know how many
            -- of the item we need yet. We'll calculate that later.

            ingredient_node = crafting_graph:add_node(ingredient_step) --[[@as RecipeGraphNode]]

            build_graph(ingredient_node)
          end
          node:connect(ingredient_node)
        end
      else
        -- We don't have a recipe for this ingredient, so we'll just add it as
        -- a node with no recipe.
        local ingredient_step = {
          item = ingredient_name,
          output_count = 0,
          needed = 0,
          crafts = 0,
          recipe = nil
        } --[[@as CraftingPlanStep]]
        -- We start with all values at zero because we don't know how many of
        -- the item we need yet. We'll calculate that later.

        local ingredient_node = crafting_graph:add_node(ingredient_step) --[[@as RecipeGraphNode]]

        node:connect(ingredient_node)
      end
    end
  end

  build_graph(root)

  return crafting_graph
end

--- Get as many recipes as possible for the given item.
---@param item string The item to get the recipes for.
---@param amount number The amount of the item to craft.
---@param max_depth number? The maximum depth to search for recipes. If set at 1, will only return the recipe for the given item. Higher values will give you recipes for items that are ingredients in the recipes for the given item. Be warned, if you set it too high and there are loops, you may have issues. Defaults to 1.
---@param max_iterations number? The total maximum number of iterations to perform. For each depth decrement, this value will also decrement. If this value reaches 0, the function will stop searching for more recipes and cancel the current recipe it was building. Defaults to 1.
---@return CraftingPlan[]? plans The crafting plans for the given item.
---@return string? error The error message if no recipe was found.
function RecipeHandler.get_all_recipes(item, amount, max_depth, max_iterations)
  return nil, "Not yet implemented."
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
    machine = machine or "crafting table"
  }

  table.insert(recipes, recipe)

  return recipe
end

--- Get a text representation of the given crafting plan.
---@param plan CraftingPlan The crafting plan to get the text representation of.
---@return string[] text The text representation of the crafting plan, where each line represents a step in the plan.
function RecipeHandler.get_plan_as_text(plan)
  local textual = {} ---@type string[]

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