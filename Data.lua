
-- fixup
require('path-compat')

-- imports
local class = require("pl.class")
local Set = require("pl.Set")
local test = require("pl.test")
local pretty = require("pl.pretty")

local Util = require("Util")

-- module

local Data = class()

function Data:_init(categories, examples)
  self.categories = categories or {}
  self.examples = examples or {}
  self:check()
end

function Data:check()

  -- Check examples against declared categories
  local cats = Set(self.categories)
  for _, v in ipairs(self.examples) do
    if not (Set{v[1]} < cats) then
      error("Example category '" .. v[1] .. "' not declared")
    end
  end

  -- Categories must be unique
  assert(Set.len(Set(self.categories)) == table.getn(self.categories))

end

function Data:write()
  return pretty.write(self)
end

function Data:read(t)
  if not Util.is_table(t) then
    t = assert(pretty.read(t))
  end
  self.categories = t.categories
  self.examples = t.examples
end

function Data:__tostring()
  return self:write()
end

-- tests

local function tests()

  -- Data
  local d = Data()
  d:check()
  d:read({categories = {"dog", "cat"}, examples = {{"dog", 1}, {"cat", 2}}})
  d:check()
  d:read({categories = {"dog", "cat"}, examples = {{"flog", 1}, {"cat", 2}}})
  test.asserteq(pcall(function() d:check() end), false)
  d:read({categories = {"dog", "cat", "dog"}, examples = {{"dog", 1}, {"cat", 2}}})
  test.asserteq(pcall(function() d:check() end), false)
end

local m = {}
m.Data = Data
m.tests = tests
return m

