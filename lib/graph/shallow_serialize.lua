--- Shallowly serialize a graph.

---@param graph Graph The graph to serialize.
---@param namefunc fun(node:GraphNode):string A function that returns the name of a node.
---@return string[] serialized Each entry is a different node.
local function shallow_serialize(graph, namefunc)
  local serialized = {} ---@type string[]

  local entry_formatter = "%s connections: %s"
  for _, node in ipairs(graph.nodes) do
    local connection_names = {}
    for _, connection in ipairs(node.connections) do
      connection_names[#connection_names + 1] = namefunc(connection)
    end
    serialized[#serialized + 1] = entry_formatter:format(
      namefunc(node),
      table.concat(connection_names, ", ")
    )
  end

  return serialized
end

return shallow_serialize