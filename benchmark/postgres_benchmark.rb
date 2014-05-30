require "active_record"
require "./lib/active_record_bulk_insert"
require 'bundler/setup'
require "benchmark"

Bundler.require(:default, :development)
options = {:adapter => "postgresql", :username => "pair", :password => "pair", :database => "bulk_insert_benchmark", :host => "localhost", port: 5433, :charset => "utf8"}
ActiveRecord::Base.establish_connection(options)
ActiveRecord::Migration.verbose = false
ActiveRecord::Migrator.migrate("benchmark/migrations")

class SampleRecord < ActiveRecord::Base
 validates :name, :presence => true
end

records = 10000.times.map { |i| {:age => i + (30..50).to_a.sample, :name => "Foo#{i}"} }

ar_records = 10000.times.map { |i| SampleRecord.new(:age => i + (30..50).to_a.sample, :name => "Foo#{i}") }

Benchmark.bmbm(25) do |x|
  x.report("Create with Active Record")  { records.each { |record| SampleRecord.create(record) } }
  x.report("AR with validations")  { SampleRecord.bulk_insert(ar_records, {:validate => true}) }
  x.report("AR without validations")  { SampleRecord.bulk_insert(ar_records) }
  x.report("Hash without validations") { SampleRecord.bulk_insert(records) }
  x.report("Hash with validations") { SampleRecord.bulk_insert(records, {:validate => true}) }
end

# ActiveRecord::Migrator.rollback("benchmark/migrations")
