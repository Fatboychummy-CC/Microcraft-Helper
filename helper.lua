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
local handler = require "recipe_handler"

local function main()
  local main_menu = require "ui.main_menu"
  local recipes_menu = require "ui.recipes_menu"
  local crafting_menu = require "ui.crafting_menu"

  --- Run the specified menu.
  ---@param name string The name of the menu to run.
  local function run_menu(name)
    if name == "recipes_menu" then
      recipes_menu(run_menu)
    elseif name == "crafting_menu" then
      crafting_menu(run_menu)
    elseif name == "main_menu" then
      main_menu(run_menu)
    else
      error("Unknown menu: " .. tostring(name), 2)
    end
  end

  print("Main menu time bois")

  run_menu("main_menu")
end

local ok, err = pcall(main)

if not ok then
  print("We in here erroring bois")
  printError(err)
  sleep(3)
end