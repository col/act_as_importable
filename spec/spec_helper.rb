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

# create the tables for the tests
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'categories'")
ActiveRecord::Base.connection.create_table(:categories) do |t|
  t.string :name
end

class Category < ActiveRecord::Base
  has_many :items
end

ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'items'")
ActiveRecord::Base.connection.create_table(:items) do |t|
  t.integer :category_id
  t.string :name
  t.float :price
end

class Item < ActiveRecord::Base
  # This line isn't needed in a real Rails app.
  include ActAsImportable::Config

  act_as_importable :uid => 'name'

  belongs_to :category

  def self.for_category(category)
    where(:category_id => category.id)
  end
end