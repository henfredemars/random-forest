
-- fixup
require('path-compat')

-- imports
local tablex = require("pl.tablex")

-- module

local function is_table(t) return type(t) == 'table' end

local function round(x)
  return math.floor(x+0.5)
end

local function random_subset(t, k)
  assert(t and k)
  t = tablex.copy(t)
  for i = table.getn(t), 2, -1 do
    local j = math.random(i)
    t[i], t[j] = t[j], t[i]
  end
  local r = {}
  tablex.icopy(r, t, 1, 1, k)
  return r
end

local function key_with_largest_value(t)
  assert(t and tablex.size(t) > 0)
  local maxkey
  local maxval
  for k, v in pairs(t) do
    if not maxval or v > maxval then
      maxkey = k
      maxval = v
    end
  end
  return maxkey, maxval
end

local m = {}
m.random_subset = random_subset
m.is_table = is_table
m.round = round
m.key_with_largest_value = key_with_largest_value
return m
