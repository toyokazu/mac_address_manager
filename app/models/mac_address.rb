require 'ipaddr'
class MacAddress < ActiveRecord::Base
  belongs_to :group
  has_many :location_mac_address_relations
  has_many :locations, :through => :location_mac_address_relations
  has_many :alias_names

  acts_as_versioned
  acts_as_paranoid

  validates_presence_of :group_id, :hostname, :mac_addr, :vlan_id

  named_scope :created_after, lambda {|time|
    return {} if time.nil?
    {:conditions => ["created_at > :time and created_at = updated_at", {:time => time}]}
  }
  named_scope :updated_after, lambda {|time|
    return {} if time.nil?
    {:conditions => ["updated_at > :time and updated_at > created_at", {:time => time}]}
  }
  named_scope :deleted_after, lambda {|time|
    return {} if time.nil?
    {:conditions => ["deleted_at > :time", {:time => time}]}
  }

  def packed_mac_addr
    MacAddress.pack_mac_addr(self.mac_addr)
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

    # the both addresses are not specified
    if (self.ipv4_addr.nil? || self.ipv4_addr.empty?) &&
        (self.ipv6_addr.nil? || self.ipv6_addr.empty?)
      errors.add(:ipv4_addr, "At least, ipv4_addr or ipv6_addr must be specified.")
      errors.add(:ipv6_addr, "At least, ipv4_addr or ipv6_addr must be specified.")
      return false
    end
    true
  end

  private
  # mac_addr
  def normalized_mac_addr
    MacAddress.normalize_mac_addr(self.mac_addr)    
  end

  def validate_mac_addr
    !self.mac_addr.nil? && MacAddress.validate_mac_addr(self.mac_addr)
  end

  class << self
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

    def pack_mac_addr(mac_addr)
      mac_addr.downcase.gsub(':', '')
    end
  end
end
