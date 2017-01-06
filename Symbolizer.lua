
-- fixup
require('path-compat')

-- imports
local class = require("pl.class")
local stringx = require("pl.stringx")
local tablex = require("pl.tablex")
local test = require("pl.test")
local pretty = require("pl.pretty")
local T = test.tuple

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

local function cleanup_text(text)
  assert(text, "No text")
  text = strip_symbols(text)
  text = stringx.strip(text)
  text = string.lower(text)
  return text
end

local function precall_words(text, word_func)
-- Clean text and split into words, then call word_func on each word

  -- Text and child word function must exist
  assert(text, "no text")
  assert(word_func, "no per-word symbol function")

  -- Clean text
  text = cleanup_text(text)

  -- Bail out if string is now empty
  if string.len(text) == 0 then
    return
  end

  -- Distribute words
  if string.find(text, " ") then
    local rvals = {}
    for _, word in ipairs(stringx.split(text)) do
      tablex.insertvalues(rvals, {word_func(word)})
    end
    return unpack(rvals)
  end

  -- Only one word
  return word_func(text)

end

local Symbolizer = class()

function Symbolizer:_init()
  self.mapper = {}
  self.idx = 1
end

function Symbolizer:gen_sym(text)
-- Convert text into symbol train, creating new symbols as needed and incrementing symbol frequences,
--   returning the freshly symbolized text symbol train

  local word_func = function(word) return Symbolizer.gen_sym_word(self, word) end
  return precall_words(text, word_func)
end

function Symbolizer:gen_sym_word(word)
-- Add a new word to the mapper, or update an existing symbol frequency, returning the symbol

  -- Increment existing word counter
  local maybe_update = self.mapper[word]
  if maybe_update then
    maybe_update.c = maybe_update.c + 1
    return maybe_update.id
  end

  -- A word never seen before
  self.mapper[word] = {id=self.idx, c=1}
  local rv = self.idx
  self.idx = self.idx + 1
  return rv
end

function Symbolizer:sym_word(word)
-- Convert word into a symbol without changing symbol frequencies

  local entry = self.mapper[word]
  return entry and entry.id
end

function Symbolizer:sym(text)
-- Convert text into symbol train using previously created symbols and without updating symbol frequencies

  local word_func = function(word) return Symbolizer.sym_word(self, word) end
  return precall_words(text, word_func)
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
end

function Symbolizer:__tostring()
  return pretty.write(self.mapper)
end

-- Tests
local function tests()
  local s = Symbolizer()
  test.asserteq(s:gen_sym(""), nil, "symbolizing not a word should return nil")
  test.asserteq(s:gen_sym("  !"), nil)
  test.asserteq(s:gen_sym("!($ >"), nil)
  test.asserteq(s:gen_sym("a"), 1, "should symbolize")
  test.asserteq(s:gen_sym("a"), 1, "should stay symbolized")
  test.asserteq(s:gen_sym("  a"), 1, "should stay symbolized")
  test.asserteq(s:gen_sym("a !"), 1, "should stay symbolized")
  test.asserteq(s:gen_sym("b"), 2, "should symbolize")
  test.asserteq(s:gen_sym("a"), 1, "should stay symbolized")
  test.asserteq(T(s:gen_sym("The quick brown fox jumps over the lazy dog.")), T(3, 4, 5, 6, 7, 8, 3, 9, 10))
  test.asserteq(s:sym("a"), 1, "should lookup 'a'")
  test.asserteq(s:sym("the"), 3, "should lookup 'the'")
  test.asserteq(s:sym("apron"), nil, "shouldn't exist")
  test.asserteq(T(s:sym("apron ball the orange a")), T(3, 1), "should give only known symbols")
  test.asserteq(T(s:sym("apron ball the orange a")), T(3, 1), "shouldn't have changed")
  s:drop(5)
  test.asserteq(s:sym("a"), 1, "should remember 'a'")
  test.asserteq(s:sym("the"), nil, "should forget 'the'")
end

return {
  strip_symbols,
  cleanup_text,
  Symbolizer,
  tests,
}
