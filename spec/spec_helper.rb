require "active_record"
require 'active_record_bulk_insert'
require "database_cleaner"
require "support/sample_record"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
if ActiveRecord::VERSION::MAJOR == 5
  MIGRATION_CLASS = ActiveRecord::Migration[5.0]
else
  MIGRATION_CLASS = ActiveRecord::Migration
end

MIGRATION_CLASS.verbose = false
ActiveRecord::Migrator.migrate("spec/support/migrations")

I18n.config.enforce_available_locales = false

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.order = "random"

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

