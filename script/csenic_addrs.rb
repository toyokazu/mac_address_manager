#!/usr/bin/env ruby

if ARGV.size < 1
  puts "usage: csenic_addrs.rb csenic_converted_filename"
  exit 1
end

csenic_addrs = nil
open(ARGV[0] || "csenic.txt", "rb") do |csenic|
  csenic_addrs = csenic.readlines
end

# data from csenic
#   mac: mac_addr
csenic_addrs.each do |csenic|
  csenic.match(/^\s*mac:\s*(([\da-z]{2}:){5}[\da-z]{2})\s*/)
  puts $1
end
  
