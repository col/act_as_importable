require 'active_support'
require 'act_as_importable'

module ActAsImportable::Config
  extend ActiveSupport::Concern

  module ClassMethods
    def act_as_importable(options = {})
      include ActAsImportable::Base

      @default_import_options = options
      @default_import_options[:uid] ||= :id
      @default_import_options[:model_class] ||= self

      # create a reader on the class to access the field name
      class << self;
        attr_reader :default_import_options
      end
    end
  end
end