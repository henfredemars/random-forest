
-- fixup
require('path-compat')

-- imports
local class = require("pl.class")
local Set = require("pl.Set")
local stringx = require("pl.stringx")
local tablex = require("pl.tablex")
local test = require("pl.test")
local pretty = require("pl.pretty")

-- module

local function strip_symbols(text)
  local ss = {}
  for i = 1, string.len(text) do
    local c = stringx.at(text, i)
    if stringx.isalnum(c) or stringx.isspace(c) then
      table.insert(ss, c)
    end
  end
  return table.concat(ss)
end

local function make_subber(list, N)
  -- Build a closure that generates all subsequences of length N

  -- Check arguments
  assert(list and N, "Missing an argument")

  -- Prevent list from changing under our feet
  list = tablex.copy(list)
  local pos = 1

  local function closure()
    if pos > (table.getn(list) - (N-1)) then
      return nil
    end
    local t = {}
    tablex.icopy(t, list, 1, pos, N)
    pos = pos + 1
    return t
  end

  return closure
end

local function cleanup_text(text)
  assert(text, "No text")
  text = strip_symbols(text)
  text = stringx.strip(text)
  text = string.lower(text)
  return text
end

local function precall_phrases(text, phrase_func, N)
-- Clean text and split into phrases, then call phrase_func on each phrase
-- Return Set of unique phrases in no particular order

  -- Text and child phrase function must exist
  assert(text, "no text")
  assert(phrase_func, "no per-phrase symbol function")

  -- Clean text
  text = cleanup_text(text)

  -- Bail out if string is now empty
  if string.len(text) == 0 then
    return Set({})
  end

  -- Distribute words
  if string.find(text, " ") then
    local words = stringx.split(text)
    local groups = {}
    for i=1,N do
      local generator = make_subber(words, i)
      local c_group = generator()
      while c_group do
        table.insert(groups, c_group)
        c_group = generator()
      end
    end
    local rvals = {}
    for _, group in ipairs(groups) do
      tablex.insertvalues(rvals, {phrase_func(table.concat(group, " "))})
    end
    return Set(rvals)
  end

  -- Only one word
  return Set{phrase_func(text)}

end

local Symbolizer = class()

function Symbolizer:_init(psize)
  self.mapper = {}
  self.idx = 1
  self.psize = psize or 2
end

function Symbolizer:gen_sym(text)
-- Learn symbols from text, returning all unique symbols found in the text

  local phrase_func = function(phrase) return Symbolizer.gen_sym_phrase(self, phrase) end
  return precall_phrases(text, phrase_func, self.psize)
end

function Symbolizer:gen_sym_phrase(phrase)
-- Insert or update phrase

  -- Increment existing phrase counter
  local maybe_update = self.mapper[phrase]
  if maybe_update then
    maybe_update.c = maybe_update.c + 1
    return maybe_update.id
  end

  -- A phrase never seen before
  self.mapper[phrase] = {id=self.idx, c=1}
  local rv = self.idx
  self.idx = self.idx + 1
  return rv
end

function Symbolizer:sym_phrase(phrase)
-- Try to convert phrase into a known symbol, without updating symbol frequencies

  local entry = self.mapper[phrase]
  return entry and entry.id
end

function Symbolizer:sym(text)
-- Search for known symbols in text

  local phrase_func = function(phrase) return Symbolizer.sym_phrase(self, phrase) end
  return precall_phrases(text, phrase_func, self.psize)
end

function Symbolizer:drop(mfreq)
-- Drop symbols with frequency less than mfreq

  local new_map = {}
  for t, d in pairs(self.mapper) do
    if d.c >= mfreq then
      new_map[t] = d
    end
  end
  self.mapper = new_map
  local mid = 1
  for _, v in ipairs(tablex.values(self.mapper)) do
    if v.id >= mid then
      mid = v.id + 1
    end
  end
  self.idx = mid
end

function Symbolizer:write()
  return pretty.write(self)
end

function Symbolizer:read(text)
  local d = assert(pretty.read(text))
  self.idx = d.idx
  self.psize = d.psize
  self.mapper = d.mapper
end

function Symbolizer:__tostring()
  return self:write()
end

-- Tests
local function tests()

  -- Symbol strippper
  test.asserteq(strip_symbols("!!Howdey?!"), "Howdey")

  -- Subsequence tests
  local g = make_subber({1, 2, 3, 4, 5}, 1)
  test.asserteq(g(), {1})
  test.asserteq(g(), {2})
  test.asserteq(g(), {3})
  test.asserteq(g(), {4})
  test.asserteq(g(), {5})
  test.asserteq(g(), nil)
  g = make_subber({1, 2, 3, 4, 5}, 2)
  test.asserteq(g(), {1, 2})
  test.asserteq(g(), {2, 3})
  test.asserteq(g(), {3, 4})
  test.asserteq(g(), {4, 5})
  test.asserteq(g(), nil)
  g = make_subber({1, 2, 3, 4, 5}, 3)
  test.asserteq(g(), {1, 2, 3})
  test.asserteq(g(), {2, 3, 4})
  test.asserteq(g(), {3, 4, 5})
  test.asserteq(g(), nil)

  -- Symbolizer
  local s = Symbolizer()
  test.asserteq(s:gen_sym(""), Set())
  test.asserteq(s:gen_sym("  !"), Set())
  test.asserteq(s:gen_sym("!($ >"), Set())
  test.asserteq(s:gen_sym("a"), Set{1})
  test.asserteq(s:gen_sym("a"), Set{1})
  test.asserteq(s:gen_sym("  a"), Set{1})
  test.asserteq(s:gen_sym("a !"), Set{1})
  test.asserteq(s:gen_sym("b"), Set{2})
  test.asserteq(s:gen_sym("a"), Set{1})
  test.asserteq(s:gen_sym("The quick fox."), Set{3, 4, 5, 6, 7})
  test.asserteq(s:sym("a"), Set{1})
  test.asserteq(s:sym("the"), Set{3})
  test.asserteq(s:sym("apron"), Set())
  test.asserteq(s:sym("apron ball the orange a"), Set{3, 1})
  test.asserteq(s:sym("apron"), Set{})
  s:drop(5)
  test.asserteq(s:sym("a"), Set{1})
  test.asserteq(s:sym("the"), Set())
  print(s)
end

local m = {}
m.strip_symbols = strip_symbols
m.cleanup_text = cleanup_text
m.make_subber = make_subber
m.Symbolizer = Symbolizer
m.tests = tests

return m
