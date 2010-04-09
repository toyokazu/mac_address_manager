class CreateLocations < ActiveRecord::Migration
  def self.up
    create_table :locations do |t|
      t.string :description
      t.string :hostname
      t.string :ipv4_addr
      t.string :ipv6_addr
      t.boolean :register_dns, :default => false
      t.boolean :selectable, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :locations
  end
end
