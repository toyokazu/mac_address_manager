class LocationMacAddressRelation < ActiveRecord::Base
  belongs_to :location
  belongs_to :mac_address

  acts_as_paranoid
  acts_as_versioned
end
