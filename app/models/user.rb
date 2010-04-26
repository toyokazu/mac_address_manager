class User < ActiveRecord::Base
  has_and_belongs_to_many :groups
  has_and_belongs_to_many :roles

  belongs_to :default_group, :class_name => "Group", :foreign_key => :default_group_id
  has_many :mac_addresses
  has_many :networks

  after_create :create_group

  def create_group
    group = Group.create(:user => self, :display_name => self.display_name)
    group.users << self
    self.default_group = group
    self.save
  end

  def before_save
    if !self.groups.include?(self.default_group)
      errors.add(:default_group, "You are not a member of the specified default_group.")
      return false
    end
  end
end
