require 'active_support'
require 'act_as_importable/base'
require 'act_as_importable/config'

module ActAsImportable
end

require 'act_as_importable/railtie.rb' if defined?(Rails)