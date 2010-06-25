class CreateWorkerRecords < ActiveRecord::Migration
  def self.up
    create_table :worker_records do |t|
      t.string :worker_type
      t.timestamp :start_at
      t.timestamp :end_at
      t.timestamp :deleted_at

      t.timestamps
    end
    WorkerRecord.create_versioned_table
  end

  def self.down
    WorkerRecord.create_versioned_table
    drop_table :worker_records
  end
end
