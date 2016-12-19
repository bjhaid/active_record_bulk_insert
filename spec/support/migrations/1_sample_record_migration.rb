class SampleRecordMigration < MIGRATION_CLASS
  def change
    create_table :sample_records do |t|
      t.text "name"
      t.integer "age"
      t.timestamps null: true
    end
  end
end

