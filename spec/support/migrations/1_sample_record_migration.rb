class SampleRecordMigration < ActiveRecord::Migration[4.2]
  def change
    create_table :sample_records do |t|
      t.text "name"
      t.integer "age"
      t.timestamps
    end
  end
end

