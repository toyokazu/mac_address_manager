#!/usr/bin/env ruby

# data from csenic
#   mac: mac_addr
while (str = $stdin.gets) do
  str.match(/^\s*mac:\s*(([\da-z]{2}:){5}[\da-z]{2})\s*/)
  puts $1
end
  
