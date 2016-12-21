[![Gem Version](https://badge.fury.io/rb/active_record_bulk_insert.svg)](http://badge.fury.io/rb/active_record_bulk_insert)
[![Gem](https://img.shields.io/gem/dt/active_record_bulk_insert.svg)](https://rubygems.org/gems/active_record_bulk_insert)
[![Build Status](https://api.travis-ci.org/bjhaid/active_record_bulk_insert.png)](https://travis-ci.org/bjhaid/active_record_bulk_insert)

# BULK INSERT


### Quick Example

For -v 1.0.0

```ruby
#Gemfile
gem "active_record_bulk_insert", :require => 'base'
```

For subsequent versions

```ruby
#Gemfile
gem "active_record_bulk_insert"
```

```ruby
users = [{:username => "foo", :firstname => "Foo", :lastname => "Bar", :age => 31},
         {:username => "j.doe", :firstname => "John", :lastname => "Doe", :age => 57}]
User.bulk_insert(users)
User.count # => 2
```

### Insert ActiveRecord Objects

```ruby
user1 = User.new({:username => "foo", :firstname => "Foo", :lastname => "Bar", :age => 31})
user2 = User.new({:username => "j.doe", :firstname => "John", :lastname => "Doe", :age => 57})
User.bulk_insert([user1, user2])
User.count # => 2
```

### Evoke Active Record Validations (after_initialize and validation callbacks)

```ruby
class User < ActiveRecord
  validates :username, :presence => true
end
users = [{:username => "foo", :firstname => "Foo", :lastname => "Bar", :age => 31},
         {:username => "j.doe", :firstname => "John", :lastname => "Doe", :age => 57},
         {:firstname => "John", :lastname => "Doe", :age => 57}]
User.bulk_insert(users, :validate => true)
# => [{:firstname => "John", :lastname => "Doe", :age => 57}]
```
*The return value is a list of invalid records*

### Provide your own primary keys

```ruby
users = [{:id => 200, :username => "foo", :firstname => "Foo", :lastname => "Bar", :age => 31},
         :id => 201, {:username => "j.doe", :firstname => "John", :lastname => "Doe", :age => 57}]
User.bulk_insert(users, :use_provided_primary_key => true)
```
*note this is only available from ActiveRecord 4.0 as id was protected from mass-assignment in ActiveRecord < 4.0*
*The return value is a list of invalid records*

### Disable default timestamps

*From version 1.0.2 updated_at and created_at are provided by default*

```ruby
User.bulk_insert(users, :disable_timestamps => true)
```

### Bulk insert in batches

```ruby
users = 1000000.times.map do |i|
  {:username => "foo#{i}", :firstname => "Foo#{i}", :lastname => "Bar#{i}", :age => (30..70).to_a.sample}
end
User.bulk_insert_in_batches(users, :batch_size => 10000, :delay => 1)
User.count # => 1000000
```

### Benchmark
DB: PostgreSQL 9.1.9  
OS: Debian GNU/Linux 7 (wheezy)  
Processor: Intel(R) Core(TM) i7-4960HQ CPU @ 2.60GHz  
Memory: 6GB  
Number of Records: 10,000  

```
                                user     system      total        real
Create with Active Record   1.970000   6.810000   8.780000 ( 14.822348)
AR with validations         0.280000   0.000000   0.280000 (  0.299018)
AR without validations      0.190000   0.000000   0.190000 (  0.207807)
Hash without validations    0.080000   0.000000   0.080000 (  0.108874)
Hash with validations       0.690000   0.000000   0.690000 (  0.669952)
```

License
bulk_insert is released under [MIT license.](http://opensource.org/licenses/MIT)
