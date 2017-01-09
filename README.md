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

What's still needed?
--------------------

- Proper implementation of cross-validation

Example?
--------

```
local s = Symbolizer()
s:gen_sym("text......")
s:gen_Sym("more text...")
s:drop(2) -- Limit to symbols occuring at least twice
local symbols = s:all_symbols()
local examples = {
    {'class1', s:sym("text...")},
    {'class2', s:sym("text...")},
}
local f = Forest{examples=examples, symbols=symbols}
f:train()
f:eval("Any new text, returns the classification")
```

