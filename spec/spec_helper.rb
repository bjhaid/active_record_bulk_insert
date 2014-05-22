require "active_record"
require 'base'
require "database_cleaner"
require "support/sample_record"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Migration.verbose = false
ActiveRecord::Migrator.migrate("spec/support/migrations")

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

