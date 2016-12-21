# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "active_record_bulk_insert"
  gem.authors       = ["Abejide Ayodele"]
  gem.email         = ["abejideayodele@gmail.com"]
  gem.description   = %q{Exposes a bulk insert API to AR subclasses}
  gem.summary       = %q{bulk insert records into the DB}
  gem.homepage      = "https://github.com/bjhaid/active_record_bulk_insert"
  gem.license       = "MIT"

  gem.files         = Dir.glob('{lib,spec}/**/*.rb') + %w{README.md}
  gem.test_files    = Dir.glob('spec/**/*')
  gem.require_path  = 'lib'
  gem.version       = "1.2.0"

  gem.add_development_dependency("activerecord", ">=3.2.0")
  gem.add_development_dependency("database_cleaner")
  gem.add_development_dependency("rspec", "2.13.0")
  gem.add_development_dependency("sqlite3")
  gem.add_development_dependency("pg", "0.17.1") if ENV['benchmark']
end
