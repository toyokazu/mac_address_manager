class CreateGroupsLocationsJoinTable < ActiveRecord::Migration
  def self.up
    create_table :groups_locations, :id => false do |t|
      t.integer :group_id
      t.integer :location_id
    end
    add_index :groups_locations, [:group_id, :location_id]
  end

  def self.down
    remove_index :groups_locations, [:group_id, :location_id]
    drop_table :groups_locations
  end
end
