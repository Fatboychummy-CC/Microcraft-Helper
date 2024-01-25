local PrimeUI = require "PrimeUI_cherrypicked"

--- A small method that essentially pcalls the given function, and if it errors, it will display the error to the user with an option to acknowledge it.
---@param f fun(): any The function to run.
---@param ... any The arguments to pass to the function.
---@return any returns The return values of the function, or nil if the function errored.
return function(f, ...)
  local values = table.pack(pcall(f, ...))
  if not values[1] then
    local w, h = term.getSize()

    -- Set up the page.
    PrimeUI.clear()
    PrimeUI.label(term.current(), 3, 2, "Microcraft Helper", colors.orange)
    PrimeUI.horizontalLine(term.current(), 3, 3, #("Microcraft Helper") + 2, colors.orange)
    PrimeUI.label(term.current(), 3, 5, "Error", colors.orange)

    PrimeUI.textBox(term.current(), 3, 7, w - 4, h - 12, values[2], colors.red)
    PrimeUI.textBox(term.current(), 3, h - 4, w - 4, 1, "Press enter to continue.", colors.white)

    PrimeUI.keyAction(keys.enter, "done")

    PrimeUI.run()
  end

  return table.unpack(values, 2, values.n)
end