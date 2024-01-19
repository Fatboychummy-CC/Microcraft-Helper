--[[
  Microcraft Helper, by fatboychummy

  This program is meant to help with packs that have large amount of
  microcrafting. You can add new crafting recipes and ask the program to
  calculate how many items are needed to craft a specific item.

  I plan to allow for multiple recipes for a single item, and to allow for
  crafting of items using machinery.

  This program will NOT craft the items for you. Rather, it will give you a
  crafting plan that you can follow.
]]

package.path = package.path .. ";lib/?.lua;lib/?/init.lua"
local handler = require "lib.recipe_handler"


-- lets pretend to craft a diamond pickaxe
-- but lets pretend that only 2 diamonds are needed, and instead of the center
-- diamond, a "stick core" is used instead (just two sticks put together)

handler.create_recipe("Diamond Pickaxe", 1, {
  {
    name = "Diamond",
    amount = 2,
    fluid = false
  },
  {
    name = "Stick Core",
    amount = 1,
    fluid = false
  },
  {
    name = "Stick",
    amount = 2,
    fluid = false
  }
})

handler.create_recipe("Stick Core", 1, {
  {
    name = "Stick",
    amount = 2,
    fluid = false
  }
})

handler.create_recipe("Stick", 4, {
  {
    name = "Wooden Plank",
    amount = 2,
    fluid = false
  }
})

handler.create_recipe("Wooden Plank", 6, {
  {
    name = "Log",
    amount = 1,
    fluid = false
  }
}, "sawmill")

handler.create_recipe("Wooden Plank", 4, {
  {
    name = "Log",
    amount = 1,
    fluid = false
  }
})

-- Insert a loop to throw things off
--[[handler.create_recipe("Stick", 2, {
  {
    name = "Stick Core",
    amount = 1,
    fluid = false
  }
})]]

handler.build_lookup()

local plan, err = handler.get_first_recipe("Diamond Pickaxe", 7, 10)
print(plan, err)

if plan then
  local textual = handler.get_plan_as_text(plan)
  require "file_helper".write("recipe.txt", table.concat(textual, "\n"))
end
