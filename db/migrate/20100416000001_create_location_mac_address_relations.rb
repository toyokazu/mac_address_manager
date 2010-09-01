class CreateLocationMacAddressRelations < ActiveRecord::Migration
  def self.up
    create_table :location_mac_address_relations do |t|
      t.integer :location_id
      t.integer :mac_address_id
      t.timestamp :deleted_at

      t.timestamps
    end
    LocationMacAddressRelation.create_versioned_table
    add_index :location_mac_address_relations, [:location_id, :mac_address_id]
  end

  def self.down
    remove_index :location_mac_address_relations, [:location_id, :mac_address_id]
    LocationMacAddressRelation.drop_versioned_table
    drop_table :location_mac_address_relations
  end
end
