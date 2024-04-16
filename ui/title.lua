--- This file contains common functionality for the title of the page, so that
--- it can be easily changed.

local PrimeUI = require "PrimeUI_cherrypicked"

local MAIN_TITLE = "Microcraft Helper"
local VERSION_STRING = "0.4.1"
local COMBINED = ("%s %s"):format(MAIN_TITLE, VERSION_STRING)

--- Create the title of the page.
return function(title, main_color, secondary_color, win)
  -- Set up the page.
  PrimeUI.label(win or term.current(), 3, 2, COMBINED, main_color)
  PrimeUI.horizontalLine(win or term.current(), 3, 3, #COMBINED + 2, main_color)
  PrimeUI.label(win or term.current(), 3, 5, title, secondary_color)
end