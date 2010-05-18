require 'ipaddr'
class MacAddress < ActiveRecord::Base
  belongs_to :group
  has_many :location_mac_address_relations
  has_many :locations, :through => :location_mac_address_relations

  acts_as_versioned
  acts_as_paranoid

  validates_presence_of :group_id, :hostname, :mac_addr

  def packed_mac_addr
    self.mac_addr.downcase.gsub(':', '')
  end

  def before_save
    # if group_id is null, set default group as admin role user found first.
    if self.group_id.nil?
      self.group_id = User.first(:conditions => {:name => 'admin'}).default_group.id
    end

    # check mac_addr format
    self.mac_addr = normalized_mac_addr
    if !validate_mac_addr
      errors.add(:mac_addr, "Specified MAC address has some format errors.")
      return false
    end

    # check ipv4_addr
    if !self.ipv4_addr.nil? && !self.ipv4_addr.empty?
      ipv4 = IPAddr.new(self.ipv4_addr)
      if !self.group.user.networks.any? { |network| network.addr.include?(ipv4) }
        errors.add(:ipv4_addr, "Specified IPv4 address is not assigned to you.")
        return false
      end
    end

    # check ipv6_addr
    if !self.ipv6_addr.nil? && !self.ipv6_addr.empty?
      ipv6 = IPAddr.new(self.ipv6_addr)
      if !self.group.user.networks.any? { |network| network.addr.include?(ipv6) }
        errors.add(:ipv6_addr, "Specified IPv6 address is not assigned to you.")
        return false
      end
    end
    true
  end

  private
  # mac_addr
  def normalized_mac_addr
    # if without ':' format, e.g. 1f2e3abb5566, then convert to 1f:2e:3a:bb:55:66.
    if self.mac_addr.match(/^\s*[\da-z]{12}\s*$/)
      self.mac_addr = self.mac_addr.gsub(/^\s*([\da-z]{2})([\da-z]{2})([\da-z]{2})([\da-z]{2})([\da-z]{2})([\da-z]{2})\s*$/, '\1:\2:\3:\4:\5:\6')
    end
    # remove spaces.
    self.mac_addr.downcase.gsub(/\s/, '')
  end

  def validate_mac_addr
    self.mac_addr.match(/^\s*([\da-z]{2}:){5}[\da-z]{2}\s*/)
  end
end
