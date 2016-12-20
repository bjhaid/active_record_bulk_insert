require 'spec_helper'

describe SampleRecord do
  describe "bulk_insert" do
    it "inserts records into the DB" do
      ActiveRecord::ConnectionAdapters::SQLite3Adapter.any_instance.should_receive(:execute).with do |params|
        params.should include("INSERT INTO \"sample_records\"")
        params.should include("Foo")
        params.should include("30")
      end.once
      SampleRecord.bulk_insert([{:name => "Foo", :age => 30}])
    end

    it "inserts records into the DB and increases count of records" do
      records = 5.times.map { |i| SampleRecord.new(:age => i + (30..50).to_a.sample, :name => "Foo#{i}").attributes }
      expect {SampleRecord.bulk_insert(records)}.to change{SampleRecord.count}.by(records.size)
    end

    it "inserts multiple records into the DB in a single insert statement" do
      records = 10.times.map { |i| {:age => 4, :name => "Foo#{i}"} }

      ActiveRecord::ConnectionAdapters::SQLite3Adapter.any_instance.should_receive(:execute).with do |params|
        matchdata = params.match(/insert into "sample_records"/i)
        matchdata.to_a.count.should == 1
        records.each do |record|
          params.should include(record[:age].to_s)
          params.should include(record[:name])
        end
      end.once

      SampleRecord.bulk_insert(records)
    end

    it "support insertion of ActiveRecord objects" do
      records = 10.times.map { |i| SampleRecord.new(:age => 4, :name => "Foo#{i}") }

      ActiveRecord::ConnectionAdapters::SQLite3Adapter.any_instance.should_receive(:execute).with do |params|
        matchdata = params.match(/insert into "sample_records"/i)
        matchdata.to_a.count.should == 1
        records.each do |record|
          params.should include(record.age.to_s)
          params.should include(record.name)
        end
      end.once

      SampleRecord.bulk_insert(records)
    end

    it "doesn't blow up on an empty array" do
      expect do
        SampleRecord.bulk_insert([])
      end.to_not raise_error
    end

    if ActiveRecord::VERSION::MAJOR >= 4
      context "use_provided_primary_key" do
        it "relies on the DB to provide primary_key if :use_provided_primary_key is false or nil" do
          records = 10.times.map { |i| SampleRecord.new(:id => 10000 + i, :age => 4, :name => "Foo#{i}") }

          ActiveRecord::ConnectionAdapters::SQLite3Adapter.any_instance.should_receive(:execute).with do |params|
            records.each do |record|
              params.should_not include(record.id.to_s)
            end
          end

          SampleRecord.bulk_insert(records)
        end

        it "uses provided primary_key if :use_provided_primary_key is true" do
          records = 10.times.map { |i| SampleRecord.new(:id => 10000 + i, :age => 4, :name => "Foo#{i}") }

          SampleRecord.bulk_insert(records, :use_provided_primary_key => true)
          records.each do |record|
            SampleRecord.exists?(:id => record.id).should be_true
          end
        end
      end
    end

    context "validations" do
      it "should not persist invalid records if ':validate => true' is specified" do
        SampleRecord.send(:validates, :name, :presence => true)
        expect {SampleRecord.bulk_insert([:age => 30], :validate => true)}.to_not change{SampleRecord.count}
      end

      it "returns the invalid records" do
        SampleRecord.send(:validates, :name, :presence => true)
        records = [{:age => 30, :name => ""}, {:age => 29, :name => "Foo"}]
        invalid_records = SampleRecord.bulk_insert(records, :validate => true, :disable_timestamps => true)
        invalid_records.should == [{:age => 30, :name => ""}]
      end
    end

    context "timestamps" do
      it "sets created_at and updated_at by default" do
        records = 10.times.map { |i| SampleRecord.new(:id => 10000 + i, :age => 4, :name => "Foo#{i}") }
        SampleRecord.bulk_insert(records)

        SampleRecord.all.each do |record|
          record.created_at.should_not be_nil
        end
      end

      it "does not set created_at and updated_at if :disable_timestamps is true" do
        records = 10.times.map { |i| SampleRecord.new(:id => 10000 + i, :age => 4, :name => "Foo#{i}") }
        SampleRecord.bulk_insert(records, :disable_timestamps => true)

        SampleRecord.all.each do |record|
          record.created_at.should be_nil
        end
      end
    end
  end

  describe "bulk_insert_in_batches" do
    it "allows you to specify a batch_size" do
      records = 10.times.map { |i| SampleRecord.new(:age => 4, :name => "Foo#{i}").attributes }

      ActiveRecord::ConnectionAdapters::SQLite3Adapter.any_instance.should_receive(:execute).with do |params|
        params.should include("INSERT INTO \"sample_records\"")
      end.exactly(5).times

      SampleRecord.bulk_insert_in_batches(records, :batch_size => 2)
    end

    it "allows you to specify a delay" do
      records = 10.times.map { |i| SampleRecord.new(:age => 4, :name => "Foo#{i}").attributes }

      SampleRecord.stub!(:sleep)
      SampleRecord.should_receive(:sleep).with(2)
      SampleRecord.bulk_insert_in_batches(records, :delay => 2)
    end

    context "validations" do
      it "returns the invalid records" do
        SampleRecord.send(:validates, :name, :presence => true)
        records = [{:age => 30, :name => ""}, {:age => 29, :name => "Foo"}]

        invalid_records = SampleRecord.bulk_insert_in_batches(records, :batch_size => 1, :validate => true, :disable_timestamps => true)
        invalid_records.should == [{:age => 30, :name => ""}]
      end
    end
  end
end
