require 'active_support'

module ActAsImportable::Config
  extend ActiveSupport::Concern

  module ClassMethods
    def act_as_importable
      include ActAsImportable::Base
    end
  end
end