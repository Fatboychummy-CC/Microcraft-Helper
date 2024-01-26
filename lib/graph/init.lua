--- A graph data structure.

local graph_node = require "graph.node"
local util = require "util"

---@class Graph
---@field nodes GraphNode[] A list of all nodes in the graph.
local graph = {}

--- Create a new graph.
---@param ... any The value of the root nodes.
---@return Graph
function graph.new(...)
  return setmetatable({nodes = {}}, {__index = graph})
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

--- Find all nodes matching a value (or a function that returns true when given the value).
---@param self Graph The graph to search.
---@param value any|fun(node:GraphNode):boolean The value to search for.
---@return GraphNode[]
function graph:find_nodes(value)
  local nodes = {}

  if type(value) == "function" then
    for _, node in ipairs(self.nodes) do
      if value(node) then
        nodes[#nodes + 1] = node
      end
    end
  else
    for _, node in ipairs(self.nodes) do
      if node.value == value then
        nodes[#nodes + 1] = node
      end
    end
  end

  return nodes
end

--- Create a clone of the graph.
---@param self Graph The graph to clone.
---@return Graph
function graph:clone()
  local new_graph = graph.new()

  local node_map = {}

  -- Pass 1: Create all nodes
  for _, node in ipairs(self.nodes) do
    node_map[node] = new_graph:add_node(util.deep_copy(node.value))
  end

  -- Pass 2: Connect all nodes
  for _, node in ipairs(self.nodes) do
    for _, connection in ipairs(node.connections) do
      node_map[node]:connect(node_map[connection])
    end
  end

  return new_graph
end


return graph