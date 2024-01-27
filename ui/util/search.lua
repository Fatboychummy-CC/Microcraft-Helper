--- A simple search page: A text box, with a list of results below.

local PrimeUI = require "PrimeUI_cherrypicked"
local fzy = require "fzy_lua"

--- Allows you to search for something.
---@param menu_subtitle string The subtitle of the menu.
---@param initial_list table<integer,string> The initial list of results. If nothing has been entered yet, this will be shown.
---@param no_selection_allowed boolean? If true, the user can select the "No results found." item and the current text will instead be returned.
---@param default_search string? The default text to show in the input box.
---@return string? text The text the user entered, or nil if the user cancelled.
return function(menu_subtitle, initial_list, no_selection_allowed, default_search)
  local w, h = term.getSize()
  local current_text = ""
  local selected = 1

  local list = initial_list

  while true do
    -- Set up the page.
    PrimeUI.clear()
    PrimeUI.label(term.current(), 3, 2, "Microcraft Helper")
    PrimeUI.horizontalLine(term.current(), 3, 3, #("Microcraft Helper") + 2)
    PrimeUI.label(term.current(), 3, 5, menu_subtitle)

    -- Draw a box around the input box.
    PrimeUI.borderBox(term.current(), 4, 7, w - 6, h - 9)

    -- Add a textbox at the bottom of the screen.
    PrimeUI.textBox(term.current(), 4, h - 1, w - 6, 1, "Press END to cancel.")
    PrimeUI.keyAction(keys["end"], "cancel")

    if no_selection_allowed then
      PrimeUI.keyCombo(keys.enter, false, false, true, function()
        PrimeUI.resolve("current_text")
      end)
    end

    PrimeUI.keyAction(keys.enter, function()
      if no_selection_allowed and list[1] == "No results found." then
        PrimeUI.resolve("current_text")
      end
    end)

    -- Ensure something exists in the list
    if #list == 0 then
      list = { "No results found." }
    end

    -- Add a list of results below the input box.
    PrimeUI.selectionBox(term.current(), 4, 9, w - 6, h - 11,
      list,
      function(sel)
        PrimeUI.resolve("done")
      end, function(sel)
        -- find the selection in the initial list
        local selection = list[sel]

        for i = 1, #initial_list do
          if initial_list[i] == selection then
            selected = i
            break
          end
        end
      end)

    -- Add a seperator between the input box and the results.
    PrimeUI.horizontalLine(term.current(), 4, 8, w - 6)

    -- Add the text input box.
    local input_name = "Text Box"
    local function input_changed(value)
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

        if #matches == 0 then
          matches = { { 0, {}, 0 } } -- this is the strangest default value I've made yet, it looks like a face
        end

        list = {}
        -- Build the list from the match scores.
        for i = 1, #matches do
          table.insert(list, initial_list[matches[i][1]] or "No results found.")
        end

        -- Set the currently selected item to the first item returned
        selected = matches[1][1]
      end


      -- Reset the page
      PrimeUI.addTask(function()
        os.queueEvent("reset_this_thing")
        os.pullEvent("reset_this_thing")
        PrimeUI.resolve("This is jank as fuck")
      end)

      return {} -- not sure if this is needed?
    end
    PrimeUI.inputBox(term.current(), 4, 7, w - 6, input_name, nil, nil, nil, nil, input_changed, current_text)


    if default_search then
      input_changed(default_search)
    end

    local input, box = PrimeUI.run()

    if input == "inputBox" and box == input_name
        or input == "done" then
      return initial_list[selected]
    elseif input == "current_text" then
      return current_text
    elseif input == "keyAction" and box == "cancel" then
      return -- cancelled.
    end
  end
end
