require 'act_as_importable/config'
require 'rails'

module ActAsImportable
  class Railtie < ::Rails::Railtie
    initializer "act_as_importable.active_record" do |app|
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.send :include, ActAsImportable::Config
      end
    end
  end
end
