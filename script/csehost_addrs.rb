#!/usr/bin/env ruby

if ARGV.size < 1
  puts "usage: csehost_addrs.rb cse_hosts_converted_filename"
  exit 1
end

csehost_addrs = nil
open(ARGV[0] || "csehost.txt", "rb") do |csehost|
  csehost_addrs = csehost.readlines
end

# converted cse_hosts.csv
# MAC (WITH_MAC): mac_addr
csehost_addrs.each do |csehost|
  csehost.match(/^MAC \(WITH_MAC\):\s*(([\da-z]{2}:){5}[\da-z]{2})\s*/)
  puts $1
end
