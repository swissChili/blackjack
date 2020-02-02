require "blackjack"

local wordCountProcessor = cmdProcessor("wc -l")
local verbatimProcessor = cmdProcessor("cat")
local mySite = Site
mySite.processors.lc = wordCountProcessor
mySite.processors.vb = verbatimProcessor

mySite:build()
