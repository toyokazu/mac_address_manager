class Location < ActiveRecord::Base
  has_many :mac_addresses
end
