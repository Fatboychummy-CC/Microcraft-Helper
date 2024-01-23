--- Common functionality between the various machine menus.

local recipe_handler = require "recipe_handler"

local common = {
  machine_list = {}
}

--- Load the recipes from the file.
function common.load()
  recipe_handler.load()
end

--- Save the recipes to the file.
function common.save()
  recipe_handler.save()
end

return common