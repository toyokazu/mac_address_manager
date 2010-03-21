class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table :groups do |t|
      t.references :user
      t.string :display_name
      t.timestamp :deleted_at

      t.timestamps
    end
  end

  def self.down
    drop_table :groups
  end
end
