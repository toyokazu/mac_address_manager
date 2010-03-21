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
  end

  def self.down
    drop_table :mac_addresses
  end
end
