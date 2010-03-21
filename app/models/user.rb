class User < ActiveRecord::Base
  has_and_belongs_to_many :groups
  has_and_belongs_to_many :roles

  has_one :group
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
end
