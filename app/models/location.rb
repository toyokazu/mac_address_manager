class Location < ActiveRecord::Base
  has_many :location_mac_address_relations
  has_many :mac_addresses, :through => :location_mac_address_relations

  named_scope :selectable, lambda {
    {:conditions => {:selectable => true}}
  }
end
