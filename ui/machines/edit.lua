local common = require "ui.machines.common"
local search = require "ui.util.search"

--- Edit machine menu -> First, search for a machine by its name.
---@param run_menu fun(name: string) The function to run another menu
return function(run_menu)
  local machine = search("Microcraft Helper", "Select Machine", {"Iron Ingot", "Gold Ingot", "Lapis Lazuli", "Stick", "Diamond Axe", "Diamond", "Log", "Wooden Plank"})
  if machine then
    -- Noot noot
  end
end