--- Short utility functions

---@class util
local util = {}

--- Deep copy a value
---@generic T
---@param t T The value to copy.
---@return T copy The copy of the value.
function util.deep_copy(t)
  if type(t) ~= "table" then
    return t
  end

  local copy = {}

  for k, v in pairs(t) do
    copy[k] = util.deep_copy(v)
  end

  return copy
end

--- Get the amount of lines output when given a specific amount of width.
---@param text string The text to check.
---@param width number The width to check.
---@return number lines The amount of lines.
function util.get_line_count(text, width)
  local win = window.create(term.current(), 1, 1, width, 100, false)

  local cx, cy = term.getCursorPos()
  local old = term.redirect(win)

  local lines = print(text)

  term.redirect(old)
  term.setCursorPos(cx, cy)

  return lines or 0
end

return util