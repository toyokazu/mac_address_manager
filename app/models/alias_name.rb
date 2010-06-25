class AliasName < ActiveRecord::Base
  belongs_to :mac_address

  acts_as_versioned
  acts_as_paranoid

  named_scope :changed_after, lambda {|time|
    return {} if time.nil?
    {:conditions => ["created_at > :time or updated_at > :time or deleted_at > :time", {:time => time}]}
  }
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
  named_scope :with_mac_address, lambda {|mac_addr|
    return {} if mac_addr.nil?
    {:conditions => {:mac_address_id => mac_addr}}
  }
end
