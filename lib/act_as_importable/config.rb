require 'active_support'

module ActAsImportable::Config
  extend ActiveSupport::Concern

  module ClassMethods
    def act_as_importable(options = {})
      include ActAsImportable::Base

      @default_import_options = options
      @default_import_options[:uid] ||= :id

      # create a reader on the class to access the field name
      class << self;
        attr_reader :default_import_options
      end
    end
  end
end