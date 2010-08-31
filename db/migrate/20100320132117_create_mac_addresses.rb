class CreateMacAddresses < ActiveRecord::Migration
  def self.up
    create_table :mac_addresses do |t|
      t.references :group
      t.string :hostname
      t.string :mac_addr
      t.string :ipv4_addr
      t.string :ipv6_addr
      t.boolean :dhcp, :default => true
      t.string :description
      t.timestamp :deleted_at

      t.timestamps
    end
    MacAddress.create_versioned_table
  end

  def self.down
    MacAddress.drop_versioned_table
    drop_table :mac_addresses
  end
end
