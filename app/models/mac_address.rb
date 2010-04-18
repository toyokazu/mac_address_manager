class MacAddress < ActiveRecord::Base
  belongs_to :group
  has_many :location_mac_address_relations
  has_many :locations, :through => :location_mac_address_relations

  validates_uniqueness_of :mac_addr, :ipv4_addr, :ipv6_addr

  def before_save
    if !self.ipv4_addr.empty?
      ipv4 = IPAddr.new(self.ipv4_addr)
      if !self.group.user.networks.any? { |network| network.addr.include?(ipv4) }
        errors.add(:ipv4_addr, "Specified IPv4 address is not assigned to you.")
        return false
      end
    end

    if !self.ipv6_addr.empty?
      ipv6 = IPAddr.new(self.ipv6_addr)
      if !self.group.user.networks.any? { |network| network.addr.include?(ipv6) }
        errors.add(:ipv6_addr, "Specified IPv6 address is not assigned to you.")
        return false
      end
    end
    true
  end

  def validate_on_update
    if self.mac_addr_changed? || self.ipv4_addr_changed?
    end
  end
end
