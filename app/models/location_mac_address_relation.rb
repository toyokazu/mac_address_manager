class LocationMacAddressRelation < ActiveRecord::Base
  belongs_to :location
  belongs_to :mac_address

  acts_as_paranoid
  acts_as_versioned

  named_scope :created_after, lambda {|at|
    return {} if at.nil?
    {:conditions => ["created_at > :at and created_at = updated_at", {:at => at}]}
  }
  named_scope :updated_after, lambda {|at|
    return {} if at.nil?
    {:conditions => ["updated_at > :at and updated_at > created_at", {:at => at}]}
  }
  named_scope :deleted_after, lambda {|at|
    return {} if at.nil?
    {:conditions => ["deleted_at > :at", {:at => at}]}
  }
  named_scope :mac_address_id, lambda {|mac_address_id|
    return {} if mac_address_id.nil?
    {:conditions => {:mac_address_id => mac_address_id}}
  }
end
