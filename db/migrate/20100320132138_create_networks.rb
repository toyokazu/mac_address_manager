class CreateNetworks < ActiveRecord::Migration
  def self.up
    create_table :networks do |t|
      t.references :user
      t.string :netaddr
      t.integer :netmask

      t.timestamps
    end
  end

  def self.down
    drop_table :networks
  end
end
