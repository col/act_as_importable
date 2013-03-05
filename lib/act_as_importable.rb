require 'act_as_importable/base'
require 'act_as_importable/config'
require 'csv'

module ActAsImportable
  include ActAsImportable::Base
end

require 'act_as_importable/railtie.rb' if defined?(Rails)
ActiveRecord::Base.send :include, ActAsImportable::Config