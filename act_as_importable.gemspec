# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'act_as_importable/version'

Gem::Specification.new do |gem|
  gem.name          = "act_as_importable"
  gem.version       = ActAsImportable::VERSION
  gem.authors       = ["Colin Harris"]
  gem.email         = ["col.w.harris@gmail.com"]
  gem.description   = %q{Helps import models from CSV files.}
  gem.summary       = %q{Helps import models from CSV files.}
  gem.homepage      = "https://github.com/Col/act_as_importable"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'activesupport', '~> 3.2.11'
  gem.add_dependency 'activerecord', '~> 3.2.11'

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "sqlite3"
end
