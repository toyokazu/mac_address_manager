class MacAddress < ActiveRecord::Base
  belongs_to :group
  has_many :location_mac_address_relations
  has_many :locations, :through => :location_mac_address_relations

  acts_as_versioned
  acts_as_paranoid

  def before_save
    if !self.ipv4_addr.nil? && !self.ipv4_addr.empty?
      ipv4 = IPAddr.new(self.ipv4_addr)
      if !self.group.user.networks.any? { |network| network.addr.include?(ipv4) }
        errors.add(:ipv4_addr, "Specified IPv4 address is not assigned to you.")
        return false
      end
    end

    if !self.ipv6_addr.nil? && !self.ipv6_addr.empty?
      ipv6 = IPAddr.new(self.ipv6_addr)
      if !self.group.user.networks.any? { |network| network.addr.include?(ipv6) }
        errors.add(:ipv6_addr, "Specified IPv6 address is not assigned to you.")
        return false
      end
    end
    true
  end
end
