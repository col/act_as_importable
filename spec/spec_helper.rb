$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'bundler/setup'
Bundler.setup(:default, :development)

require 'active_record'
require 'active_support'
require 'act_as_importable'
require 'rspec'
require 'rspec/autorun'

root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
ActiveRecord::Base.establish_connection(
    :adapter => "sqlite3",
    :database => "#{root}/db/act_as_importable.db"
)

RSpec.configure do |config|
end