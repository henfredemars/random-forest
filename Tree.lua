
-- fixup
require('path-compat')

-- imports
local class = require("pl.class")
local Set = require("pl.Set")
local test = require("pl.test")
local pretty = require("pl.pretty")
local C = require("pl.comprehension").new()

-- module

local Tree = class()

function Tree:_init(symbol, left, right, term)
  self.symbol = symbol
  self.left = left
  self.right = right
  self.term = term
  assert(symbol or term, "Node must be a decision node or a leaf node")
end

function Tree:eval(sample)
-- Classify a sample Set{symbols}

  assert(sample)

  -- Leaf node
  if self.term then
    return self.term
  end

  -- Else, walk the tree
  if Set{self.symbol} < sample then
    if self.right then
      return self.right:eval(sample)
    else
      return
    end
  else
    if self.left then
      return self.left:eval(sample)
    else
      return
    end
  end
end

function Tree:read(t)
  if type(t) ~= 'table' then
    t = assert(pretty.read(t))
  end
  self.term = t.term
  self.left = t.left
  self.right = t.right
  self.symbol = t.symbol
end

function Tree:write()
  return pretty.write(self)
end

function Tree:__tostring()
  return self:write()
end

local function entropy(examples, all_symbols)
  assert(all_symbols and Set.len(all_symbols) > 0)
  local e = 0
  local N = Set.len(all_symbols)
  for symbol, _ in pairs(all_symbols) do
    local rpool = C "x for _,x in ipairs(_1) if _2 < x[2]" (examples, Set{symbol})
    local p = table.getn(rpool)/N
    e = e + p*math.log10(p)
  end
  return -e
end

local function most_popular_category(examples)
  assert(examples and table.getn(examples) > 0)
  local catcounts = {}
  for _, v in ipairs(examples) do
    if catcounts[v[1]] then
      catcounts[v[1]] = catcounts[v[1]] + 1
    else
      catcounts[v[1]] = 1
    end
  end
  local maxkey
  local maxval
  for k, v in pairs(catcounts) do
    if not maxval or v > maxval then
      maxkey = k
      maxval = v
    end
  end
  return maxkey
end

local function build_tree(examples, symbols)
-- ID3 algorithm for building a decision tree
-- Examples should be a table of examples {category, Set{symbols}}

  -- Argument checking
  assert(examples, "missing examples table")
  assert(table.getn(examples) > 0, "need at least one elment to classify")

  -- No symbols to split on, terminate with most popular category
  if Set.len(symbols) == 0 then
    return Tree(nil, nil, nil, most_popular_category(examples))
  end

  -- Examples all in the same category
  local only_category = examples[1][1]
  local objection
  for _, v in ipairs(examples) do
    if v[1] ~= only_category then
      objection = true
    end
  end
  if not objection then
    return Tree(nil, nil, nil, only_category)
  end

  -- Find the best symbol to split on
  local N = Set.len(symbols)
  local candidate_symbol
  local candidate_lpool
  local candidate_rpool
  local candidate_information_gain
  for v, _ in pairs(symbols) do

    -- Divide the examples based on this symbol
    local lpool = C "x for _,x in ipairs(_1) if not(_2 < x[2])" (examples, Set{v})
    local rpool = C "x for _,x in ipairs(_1) if _2 < x[2]" (examples, Set{v})
    local lpooln = table.getn(lpool)
    local rpooln = table.getn(rpool)

    -- Information gain
    local lpool_entropy = entropy(lpool, symbols)
    local rpool_entropy = entropy(rpool, symbols)
    local new_entropy = (lpooln/N)*lpool_entropy +(rpooln/N)*rpool_entropy
    local new_information_gain = entropy(examples, symbols) - new_entropy
    if not candidate_information_gain or new_information_gain > candidate_information_gain then
      candidate_symbol = v
      candidate_lpool = lpool
      candidate_rpool = rpool
      candidate_information_gain = new_information_gain
    end
  end
  local lpool = candidate_lpool
  local rpool = candidate_rpool

  -- No good split was found
  if table.getn(lpool) == 0 or table.getn(rpool) == 0 then
    return Tree(nil, nil, nil, most_popular_category(examples))
  end

  -- Build tree node
  local t = Tree(candidate_symbol, lpool, rpool)

  -- Recursive build child nodes
  local nsymbols = symbols - Set{candidate_symbol}
  t.left = build_tree(lpool, nsymbols)
  t.right = build_tree(rpool, nsymbols)

  return t
end

-- Test
local function tests()
  local examples = {
    {'a', Set{1, 2, 3}},
    {'b', Set{1, 2, 3}},
    {'b', Set{1, 2, 3}},
  }
  local symbols = Set{1, 2, 3}
  test.asserteq(entropy(examples, symbols), 0, 0.01)
  examples[1][2] = Set({1, 2})
  assert(math.abs(entropy(examples, symbols)) > 0.1)
  test.asserteq(most_popular_category(examples), 'b')
  examples = {
    {'a', Set{1, 2, 3}},
  }
  local t = build_tree(examples, symbols)
  test.asserteq(t.term, 'a')
  test.asserteq(t.left or t.right or t.symbol, nil)
  examples[2] = {'a', Set{1, 2, 3}}
  t = build_tree(examples, symbols)
  test.asserteq(t.term, 'a')
  test.asserteq(t.left or t.right or t.symbol, nil)
  t = build_tree(examples, Set{})
  test.asserteq(t.term, 'a')
  test.asserteq(t.left or t.right or t.symbol, nil)
  examples = {
    {'a', Set{1}},
    {'b', Set{2}},
    {'c', Set{3}}
  }
  t = build_tree(examples, symbols)
  test.asserteq(t:eval(Set{1}), "a")
  test.asserteq(t:eval(Set{2}), "b")
  test.asserteq(t:eval(Set{3}), "c")
  examples = {
    {'c', Set{3}},
    {'c', Set{4}},
    {'a', Set{1}},
    {'b', Set{2}},
    {'c', Set{5}},
  }
  symbols = Set{1, 2, 3, 4, 5}
  t = build_tree(examples, symbols)
  test.asserteq(t:eval(Set{1}), "a")
  test.asserteq(t:eval(Set{2}), "b")
  test.asserteq(t:eval(Set{3}), "c")
  test.asserteq(t:eval(Set{4}), "c")
  test.asserteq(t:eval(Set{5}), "c")
end

local m = {}
m.Tree = Tree
m.build_tree = build_tree
m.most_popular_category = most_popular_category
m.entropy = entropy
m.tests = tests
return m
