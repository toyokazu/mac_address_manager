class CreateLocations < ActiveRecord::Migration
  def self.up
    create_table :locations do |t|
      t.string :description
      t.string :hostname
      t.string :hosttype
      t.string :ipv4_addr
      t.string :ipv6_addr
      t.boolean :register_dns, :default => false
      t.boolean :selectable, :default => false
      t.timestamp :deleted_at

      t.timestamps
    end
    Location.create_versioned_table
  end

  def self.down
    Location.drop_versioned_table
    drop_table :locations
  end
end
