--- A simple search page: A text box, with a list of results below.

local PrimeUI = require "PrimeUI_cherrypicked"
local fzy = require "fzy_lua"

--- Allows you to search for something.
---@param menu_name string The name of the menu.
---@param menu_subtitle string The subtitle of the menu.
---@param initial_list table<integer,string> The initial list of results. If nothing has been entered yet, this will be shown.
---@return string? text The text the user entered, or nil if the user cancelled.
return function(menu_name, menu_subtitle, initial_list)
  local w, h = term.getSize()
  local current_text = ""
  local selected = initial_list[1]

  local list = initial_list

  while true do
    -- Set up the page.
    PrimeUI.clear()
    PrimeUI.label(term.current(), 3, 2, menu_name)
    PrimeUI.horizontalLine(term.current(), 3, 3, #menu_name + 2)
    PrimeUI.label(term.current(), 3, 5, menu_subtitle)

    -- Draw a box around the input box.
    PrimeUI.borderBox(term.current(), 4, 7, w - 6, h - 9)

    -- Add a textbox at the bottom of the screen.
    PrimeUI.textBox(term.current(), 4, h - 1, w - 6, 1, "Press END to cancel.")
    PrimeUI.keyAction(keys["end"], "cancel")

    -- Add a list of results below the input box.
    PrimeUI.selectionBox(term.current(), 4, 9, w - 6, h - 11,
      list,
      function(sel)
        PrimeUI.resolve("done")
      end, function(sel)
        -- todo: this
    end)

    -- Add a seperator between the input box and the results.
    PrimeUI.horizontalLine(term.current(), 4, 8, w - 6)

    -- Add the text input box.
    local input_name = "Text Box"
    PrimeUI.inputBox(term.current(), 4, 7, w - 6, input_name, nil, nil, nil, nil, function(value)
      local changed = current_text ~= value
      if not changed then
        return {}
      end

      current_text = value

      if current_text == "" then
        -- Just show the initial list
        list = initial_list
      else
        -- Update the list of results
        local matches = fzy.filter(current_text, initial_list)

        -- If there are no matches, show a list with a blank entry.
        if #matches == 0 then
          matches = {""}
        end

        list = {}
        -- Build the list from the match scores.
        for i = 1, #matches do
          table.insert(list, initial_list[matches[i][1]])
        end
      end


      -- Reset the page
      PrimeUI.addTask(function()
        os.queueEvent("reset_this_thing")
        os.pullEvent("reset_this_thing")
        PrimeUI.resolve("This is jank as fuck")
      end)

      return {} -- not sure if this is needed?
    end, current_text)

    local input, box, value = PrimeUI.run()

    if input == "inputBox" and box == input_name and value ~= "" then
      return value
    end
  end
end