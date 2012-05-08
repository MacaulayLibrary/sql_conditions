# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sql_conditions/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Brian Maltzan"]
  gem.email         = ["brian.maltzan@gmail.com"]
  gem.description   = %q{Help create conditions array to pass to activerecord}
  gem.summary       = %q{Assist with and/or, and a few helpers}
  gem.homepage      = "https://github.com/MacaulayLibrary/sql_conditions"

  gem.add_development_dependency "rspec"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "sql_conditions"
  gem.require_paths = ["lib"]
  gem.version       = SqlConditions::VERSION
end
