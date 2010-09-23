#!/usr/bin/env ruby

require 'csv'

if ARGV.size < 1
  puts "usage: normalize_google_docs.rb csv_filename"
  exit 1
end

def normalize_mac_addr(mac_addr)
  # convert to lower-case alphabets and remove spaces.
  mac_addr = mac_addr.downcase.gsub(/\s/, '')
  # if without ':' format, e.g. 1f2e3abb5566, then convert to 1f:2e:3a:bb:55:66.
  if mac_addr.match(/^\s*[\da-z]{12}\s*$/)
    mac_addr = mac_addr.gsub(/^\s*([\da-z]{2})([\da-z]{2})([\da-z]{2})([\da-z]{2})([\da-z]{2})([\da-z]{2})\s*$/, '\1:\2:\3:\4:\5:\6')
  end
  mac_addr
end

def validate_mac_addr(mac_addr)
  mac_addr.match(/^\s*([\da-z]{2}:){5}[\da-z]{2}\s*/)
end

# cse_hosts.csv from Google Docs
# IPaddr, hostname, MACaddr, Comments, Supplemental
# row[0], row[1],   row[2],  row[3],   row[4]
CSV::Reader.parse(File.open(ARGV[0] || "cse_hosts.csv", "rb")) do |row|
  status = "NOT_ASSIGNED"
  if !row[2].nil?
    row[2] = normalize_mac_addr(row[2])
    if !validate_mac_addr(row[2])
      # comment line may be come here
      next
    end
    status = "WITH_MAC"
  elsif !row[1].nil?
    status = "WITHOUT_MAC"
  end
  puts "--"
  puts "IP (#{status}): #{row[0]}, "
  puts "hostname (#{status}): #{row[1]}"
  puts "MAC (#{status}): #{row[2]}"
  puts "Comment (#{status}): #{row[3]}"
  puts "Supplemental (#{status}): #{row[4]}"
end
