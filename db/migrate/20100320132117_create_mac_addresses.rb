class CreateMacAddresses < ActiveRecord::Migration
  def self.up
    create_table :mac_addresses do |t|
      t.references :group
      t.string :hostname
      t.string :mac_addr
      t.string :ipv4_addr
      t.string :ipv6_addr
      t.references :location
      t.string :description
      t.timestamp :deleted_at

      t.timestamps
    end
    add_index :mac_addresses, :mac_addr, :unique => true
    add_index :mac_addresses, :ipv4_addr, :unique => true
    add_index :mac_addresses, :ipv6_addr, :unique => true
  end

  def self.down
    remove_index :mac_addresses, :ipv6_addr
    remove_index :mac_addresses, :ipv4_addr
    remove_index :mac_addresses, :mac_addr
    drop_table :mac_addresses
  end
end
