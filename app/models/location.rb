class Location < ActiveRecord::Base
  has_many :location_mac_address_relations
  has_many :mac_addresses, :through => :location_mac_address_relations
  has_and_belongs_to_many :groups
  acts_as_versioned
  acts_as_paranoid

  named_scope :selectable, lambda {
    {:conditions => {:selectable => true}}
  }

  def before_save
    self.hosttype = self.hosttype.classify
    begin
      hosttype_class = eval "SSH::#{self.hosttype}"
      raise if hosttype_class.class != Class || !hosttype_class.ancestors.include?(SSH::Base)
    rescue
      errors.add(:hosttype, "Specified hosttype is not supported.")
      return false
    end
  end
end
