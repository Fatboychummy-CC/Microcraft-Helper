local PrimeUI = require "PrimeUI_cherrypicked"

---@class MenuOption
---@field name string The name of the option.
---@field description string? The description of the option, if any.
---@field action fun() The action to run when the option is selected.

--- Create a menu with a list of options and their actions (with optional go-back button).
---@param title string The title of the menu.
---@param options table<integer, MenuOption> The options to display, with their actions.
---@param go_back boolean Whether to add a go-back button.
---@param go_back_top boolean Whether to put the go-back button at the top. Places at the bottom otherwise.
---@param go_back_text string? The text to use for the go-back button. Defaults to "Go Back".
return function(title, options, go_back, go_back_top, go_back_text)
  go_back_text = go_back_text or "Go Back"
  local tw, th = term.getSize()

  while true do
    -- The list of possible menus
    local menus = {}
    local height = 0
    local len = tw - 9
    for _, v in pairs(options) do
      height = height + 1
      table.insert(menus, v.name)
    end

    if go_back then
      height = height + 1
      len = math.max(len, #go_back_text)
      if go_back_top then
        table.insert(menus, 1, go_back_text)
      else
        table.insert(menus, go_back_text)
      end
    end

    if height > 5 then height = 5 end

    -- Set up the page.
    PrimeUI.clear()
    PrimeUI.label(term.current(), 3, 2, "Microcraft Helper")
    PrimeUI.horizontalLine(term.current(), 3, 3, #("Microcraft Helper") + 2)
    PrimeUI.label(term.current(), 3, 5, title)

    -- Set up the textbox (directly below the selection box)
    local redraw_textbox = PrimeUI.textBox(term.current(), 4, 7 + height + 2, len + 3, th - 7 - height, options[1].description or "")

    -- Set up the selection box
    local selected = menus[1]
    PrimeUI.selectionBox(term.current(), 4, 7, len + 3, height, menus, function(sel)
      selected = sel
      PrimeUI.resolve("done")
    end, function(sel)
      redraw_textbox(options[sel] and options[sel].description or "")
    end)

    -- Add a border around it
    PrimeUI.borderBox(term.current(), 4, 7, len + 3, height)

    PrimeUI.run()

    -- Run the selected menu, or exit if we're done
    if selected == go_back_text then
      return
    else
      for _, v in pairs(options) do
        if v.name == selected then
          v.action()
          break
        end
      end
    end
  end
end