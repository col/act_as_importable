require 'bundler/gem_tasks'
require 'act_as_importable/version'
require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new :spec

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "ActAsImportable #{ActAsImportable::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end