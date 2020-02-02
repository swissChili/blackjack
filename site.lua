require "blackjack"

local wordCountProcessor = cmdProcessor("wc -l")
local verbatimProcessor = cmdProcessor("cat")
local mySite = Site
mySite.processors.lc = {
  process = wordCountProcessor,
  extension = "txt"
}
mySite.processors.vb = {
  process = verbatimProcessor,
  extension = "html"
}

mySite:build()
