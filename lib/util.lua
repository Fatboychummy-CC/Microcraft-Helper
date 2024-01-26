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

return util