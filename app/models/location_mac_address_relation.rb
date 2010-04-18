class LocationMacAddressRelation < ActiveRecord::Base
  belongs_to :location
  belongs_to :mac_address
end
