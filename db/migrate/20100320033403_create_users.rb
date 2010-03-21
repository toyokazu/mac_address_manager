class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :name
      t.string :display_name
      t.string :contact
      t.references :default_group
      t.timestamp :deleted_at

      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
