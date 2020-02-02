package = "blackjack"
version = "0.1.0-1"
source = {
   url = "https://git.sr.ht/~swisschili/blackjack"
}
description = {
   summary = "Blackjack is a simple and extremely extensible static site generator written in lua.",
   detailed = [[
Blackjack is a simple and extremely extensible static site generator
written in lua.
]],
   homepage = "https://blackjack.swisschili.sh",
   license = "GPL-3.0"
}
dependencies = {}
build = {
   type = "builtin",
   modules = {
      blackjack = "blackjack.lua"
   }
}
