require 'ipaddr'

class Network < ActiveRecord::Base
  belongs_to :user

  def addr
    IPAddr.new("#{self.netaddr}/#{self.netmask}")
  end
end
