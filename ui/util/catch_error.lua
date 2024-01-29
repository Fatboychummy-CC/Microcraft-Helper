local PrimeUI = require "PrimeUI_cherrypicked"

--- A small method that essentially pcalls the given function, and if it errors, it will display the error to the user with an option to acknowledge it.
---@param f fun(): any The function to run.
---@param ... any The arguments to pass to the function.
---@return any returns The return values of the function, or nil if the function errored.
return function(f, ...)
  local values = table.pack(xpcall(f, debug.traceback, ...))
  if not values[1] then
    if values[2] == "terminate_elevated" then
      -- Program termination requested and was elevated by a previous catch_error.
      return
    end

    local w, h = term.getSize()

    -- Set up the page.
    PrimeUI.clear()
    require "ui.title" ("Error", colors.orange, colors.orange)

    PrimeUI.textBox(term.current(), 3, 7, w - 4, h - 12, values[2], colors.red)
    PrimeUI.textBox(term.current(), 3, h - 4, w - 4, 1, "Press enter to continue.", colors.white)

    PrimeUI.keyAction(keys.enter, "done")

    PrimeUI.run()

    if values[2] == "Terminated" then
      -- elevate the error
      error("terminate_elevated", 0)
    end
  end

  return table.unpack(values, 1, values.n)
end
