class CreateRolesUsersJoinTable < ActiveRecord::Migration
  def self.up
    create_table :roles_users, :id => false do |t|
      t.integer :role_id
      t.integer :user_id
    end
    add_index :roles_users, [:role_id, :user_id]
  end

  def self.down
    remove_index :roles_users, [:role_id, :user_id]
    drop_table :roles_users
  end
end
