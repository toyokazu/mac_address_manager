class CreateMacAddresses < ActiveRecord::Migration
  def self.up
    create_table :mac_addresses do |t|
      t.references :group
      t.string :hostname
      t.string :mac_addr
      t.string :ipv4_addr
      t.string :ipv6_addr
      t.integer :vlan_id, :default => 92
      t.boolean :dhcp, :default => true
      t.string :description
      t.timestamp :deleted_at

      t.timestamps
    end
    MacAddress.create_versioned_table
    add_index :mac_addresses, :group_id
    add_index :mac_addresses, [:hostname, :mac_addr, :ipv4_addr, :ipv6_addr]
  end

  def self.down
    remove_index :mac_addresses, [:hostname, :mac_addr, :ipv4_addr, :ipv6_addr]
    remove_index :mac_addresses, :group_id
    MacAddress.drop_versioned_table
    drop_table :mac_addresses
  end
end
