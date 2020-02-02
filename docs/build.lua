require "blackjack"

site = Site
site.processors.scss = {
  process = cmdProcessor("sass -"),
  extension = "css"
}

site:build()
