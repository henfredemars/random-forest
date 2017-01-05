
-- fixup
require('path-compat')

-- imports
local class = require("pl.class")
local stringx = require("pl.stringx")
local tablex = require("pl.tablex")

-- module

local function stripsymbols(text)
  local ss = {}
  for i = 1, string.len(text) do
    local c = stringx.at(text, i)
    if stringx.isalnum(c) or stringx.isspace(c) then
      table.insert(ss, c)
    end
  end
  return table.concact(ss)
end

local Symbolizer = class()

function Symbolizer:_init()
  self.mapper = {}
  self.idx = 1
end

function Symbolizer:sym(text)

  -- Strip symbols and trim whitespace
  text = stripsymbols(text)
  text = stringx.strip(text)

  -- Bail out if string is empty
  if string.len(text) == 0 then
    return
  end

  -- Words
  if string.find(text, " ") then
    local rvals = {}
    for _, word in ipairs(stringx.split(text)) do
      tablex.insertvalues(rvals, {self.sym(word)})
    end
    return unpack(rvals)
  end

  -- Bail out if word already symbolized
  local maybe_sim = self.mapper[text]
  if maybe_sim then
    return maybe_sim
  end

  -- A word never seen before
  self.mapper[text] = self.idx
  local rv = self.idx
  self.idx = self.idx + 1
  return rv
end

return {stripsymbols, Symbolizer}
