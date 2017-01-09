# random-forest

Random forest implementation in Lua 5.1
=======================================

This is a Lua implementation of random forests using ID3 decision trees for text classifiaction (also implemented here in Lua) 
targeting Lua 5.1 compatibility. This project is educational in nature---I make no claims as to its suitability for any 
purpose. If you are considering this rock for inclusion in your project, please understand that is not suitable for 
production.

Why did you decide on this project?
-----------------------------------

- Closer understanding of a popular machine learning approach
- Hands-on experience with a small, fast, and highly-embeddable dynamic language
- Hobby project to keep me occupied spring of 2017

Overwhelmingly, this project is about learning and having fun with Lua!

What works?
-----------

- Text tokenization (words or phrases)
- Decision trees
- Randomized decision trees
- Random forests
- Tree and data serialization

What's still needed?
--------------------

- Proper implementation of cross-validation
- Better documentation and a documentation generation scheme

Example?
--------

```
Symbolizer = require("Symbolizer").Symbolizer
Forest = require("Forest").Forest
local s = Symbolizer()
s:gen_sym("text needed to be converted into a set of symbols...")
s:gen_sym("more text...")
s:drop(2) -- Limit to symbols occuring at least twice
local symbols = s:all_symbols()
local examples = {
    {'class1', s:sym("text...")},
    {'class2', s:sym("text...")},
}
local f = Forest{examples=examples, symbols=symbols, size=10}
f:train()
f:eval("Any new text, returns the classification")
```

Tuning parameters for the Forest:

- node_factor: what proportion of features should be considered at random when choosing the best feature to split on?
- bag_factor: what proportion of all known features should be considered when creating a random tree root?

How should I use this?
----------------------

Make sure that you have Lua 5.1 (it may or may not work in other versions--not tested) and penlight installed. Files contain 
examples. I have not yet written a script to automatically generate documentation, but additional options and configuration 
should be evident. I use a utility script called path-compat that you will likely need to change to match your real path, or 
simply delete the file if you are not using LuaJIT from the Ubuntu repositories. (If you are, you will need to set your PATH 
and CPATH there to match your Lua installation's defaults for CLua).

The only feature that comes to mind that isn't shown in the above example is the ability to serialize both data and 
fully-generated trees into text or tables, and the phrasing size in the Symbolizer is adjustable with a trivial argument.
