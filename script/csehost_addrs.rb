#!/usr/bin/env ruby

# converted cse_hosts.csv
# MAC (WITH_MAC): mac_addr
while (str = $stdin.gets) do
  str.match(/^MAC \(WITH_MAC\):\s*(([\da-z]{2}:){5}[\da-z]{2})\s*/)
  puts $1
end
