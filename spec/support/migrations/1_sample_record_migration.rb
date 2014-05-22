class SampleRecordMigration < ActiveRecord::Migration
  def change
    create_table :sample_records do |t|
      t.text "name"
      t.integer "age"
    end
  end
end

