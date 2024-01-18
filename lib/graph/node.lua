--- Methods for a single graph node.

---@class GraphNode
---@field value any The value of the node.
---@field connections GraphNode[] The nodes connected to this node.
---@field graph Graph The graph this node belongs to.
local graph_node = {}

--- Create a new graph node.
---@param value any The value of the node.
---@param parent_graph Graph The graph this node belongs to.
---@return GraphNode
function graph_node.new(value, parent_graph)
  local node = {
    value = value,
    connections = {},
    graph = parent_graph
  }

  parent_graph.nodes[#parent_graph.nodes + 1] = node

  return setmetatable(node, {__index = graph_node})
end

--- Connect this node to another node.
---@param self GraphNode The node to connect from.
---@param node GraphNode The node to connect to.
function graph_node.connect(self, node)
  table.insert(self.connections, node)
  table.insert(node.connections, self)
end

--- Disconnect this node from another node.
---@param self GraphNode The node to disconnect from.
---@param node GraphNode The node to disconnect.
function graph_node.disconnect(self, node)
  for i = #self.connections, 1, -1 do
    if self.connections[i] == node then
      table.remove(self.connections, i)
    end
  end

  for i = #node.connections, 1, -1 do
    if node.connections[i] == self then
      table.remove(node.connections, i)
    end
  end
end

--- Check if this node is connected to another node.
---@param self GraphNode The node to check from.
---@param node GraphNode The node to check.
---@return boolean connected
function graph_node.is_connected(self, node)
  for _, connection in ipairs(self.connections) do
    if connection == node then
      return true
    end
  end

  return false
end

return graph_node