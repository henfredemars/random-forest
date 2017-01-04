package = "random-forest"
version = "0-1"
source = {
   url = "https://github.com/henfredemars/random-forest"
}
description = {
   summary = "Random forests in Lua",
   detailed = [[
Random forest implementation in Lua 5.1
]],
   homepage = "https://github.com/henfredemars/random-forest",
   license = "MIT License (provided)"
}
dependencies = {
   "lua ~> 5.1"
}
build = {
   type = "builtin",
   modules = {}
}
