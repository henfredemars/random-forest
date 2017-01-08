
-- fixup
require('path-compat')

-- imports
local class = require("pl.class")
local Set = require("pl.Set")
local pretty = require("pl.pretty")

local Tree = require("Tree")
local Util = require("Util")

-- module

local Forest = class()

function Forest:_init(t)
  self.examples = t.examples
  self.symbols = t.symbols
  self.size = t.size or 15
  self.bag_factor = t.bag_factor or 0.8
  self.node_factor = t.node_factor or 0.5
  self.trees = t.trees
end

function Forest:train()
  assert(self.examples and self.symbols)
  self.trees = {}
  for i = 1, self.size do
    local t_symbols = Util.random_subset(Set.values(self.symbols), math.ceil(self.bag_factor*Set.len(self.symbols)))
    assert(table.getn(t_symbols) > 0)
    self.trees[i] = Tree.build_tree(self.examples, t_symbols, self.node_factor)
  end
end

function Forest:eval(sample)
  -- Sample is Set{symbols}
  local r = {}
  for i = 1, self.size do
    local tree = self.trees[i]
    local reply = tree:eval(sample)
    if r[reply] then
      r[reply] = r[reply] + 1
    else
      r[reply] = 1
    end
  end
  return Util.key_with_largest_value(r)
end

function Forest:read(t)
  if not Util.is_table(t) then
    t = assert(pretty.read(t))
  end
  self._init(t)
end

function Forest:write()
  return pretty.write(self)
end

function Forest:__tostring()
  return self:write()
end

-- tests
local function tests()
  local examples = {
    {'c', Set{3}},
    {'c', Set{4}},
    {'a', Set{1}},
    {'b', Set{2}},
    {'c', Set{5}},
  }
  local symbols = Set{1, 2, 3, 4, 5}
  local f = Forest{examples=examples, symbols=symbols}
  f:train()
  print(f:eval(Set{4}))
end
tests()

local m = {}
m.Forest = Forest
m.tests = tests
return m
