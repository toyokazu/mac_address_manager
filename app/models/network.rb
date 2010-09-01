require 'ipaddr'

class Network < ActiveRecord::Base
  belongs_to :user

  def addr
    IPAddr.new("#{self.netaddr}/#{self.netmask}")
  end

  class << self
    def next_ip(user)
      user.networks.each do |network|
        range = network.addr.to_range
        network_addr = range.first
        broadcast_addr = range.last
        range.each do |ip_addr|
          next if (ip_addr == network_addr || ip_addr == broadcast_addr)
          using_entry = MacAddress.first(:conditions => {:ipv4_addr => ip_addr.to_s})
          return ip_addr if using_entry.nil?
        end
      end
      nil
    end
  end
end
