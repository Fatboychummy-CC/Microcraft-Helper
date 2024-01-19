--- A graph data structure.

local graph_node = require "graph.node"

---@class Graph
---@field root GraphNode The root node of the graph.
---@field nodes GraphNode[] A list of all nodes in the graph.
local graph = {}

--- Create a new graph.
---@param root_value any The value of the root node.
---@return Graph
function graph.new(root_value)
  local obj = {
    nodes = {}
  }
  local root = graph_node.new(root_value, obj)
  obj.root = root

  ---@cast obj Graph

  return setmetatable(obj, {__index = graph})
end

--- Add a new node to the graph.
---@param self Graph The graph to add to.
---@param value any The value of the node.
---@return GraphNode
function graph:add_node(value)
  return graph_node.new(value, self)
end

--- Find a node given its value (or a function that returns true when given the value).
---@param self Graph The graph to search.
---@param value any|fun(node:GraphNode):boolean The value to search for.
---@return GraphNode?
function graph:find_node(value)
  if type(value) == "function" then
    for _, node in ipairs(self.nodes) do
      if value(node) then
        return node
      end
    end
  else
    for _, node in ipairs(self.nodes) do
      if node.value == value then
        return node
      end
    end
  end
end


return graph