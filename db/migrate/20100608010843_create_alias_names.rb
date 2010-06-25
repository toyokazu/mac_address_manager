class CreateAliasNames < ActiveRecord::Migration
  def self.up
    create_table :alias_names do |t|
      t.references :mac_address
      t.string :hostname
      t.string :description
      t.timestamp :deleted_at

      t.timestamps
    end
    AliasName.create_versioned_table
  end

  def self.down
    AliasName.drop_versioned_table
    drop_table :alias_names
  end
end
