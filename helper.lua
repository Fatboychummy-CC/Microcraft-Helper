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

local function main()
  --- Run the specified menu.
  ---@param name string The name of the menu to run.
  local function run_menu(name)
    local ok, value = pcall(require, "ui." .. name) -- efficient_code.exe

    if not ok then
      error("Failed to load menu: " .. tostring(name) .. ": " .. tostring(value), 2)
    end

    if type(value) ~= "function" then
      error("Menu " .. tostring(name) .. " is not a function, it is a " .. type(value), 2)
    end

    value(run_menu) -- Run the menu
  end

  print("Main menu time bois")

  run_menu("main_menu")
end

local ok, err = pcall(main)

print() -- Put the cursor onto the screen with a quick lil print
if not ok then
  printError(err)
end