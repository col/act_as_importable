require 'active_support'
require 'act_as_importable/importer'
require 'act_as_importable/csv_importer'

module ActAsImportable
  module Base
    extend ActiveSupport::Concern

    included do

      # This is used to store the data being import when there is an error
      attr_accessor :import_data

    end

    module ClassMethods

      def import_csv_file(file, options = {})
        options.reverse_merge!(@default_import_options)
        importer = ActAsImportable::CSVImporter.new(options)
        importer.import_csv_file(file)
        importer
      end

      def import_csv_text(text, options = {})
        options.reverse_merge!(@default_import_options)
        importer = ActAsImportable::CSVImporter.new(options)
        importer.import_csv_text(text)
        importer
      end

      def import_data(data, options = {})
        options.reverse_merge!(@default_import_options)
        importer = ActAsImportable::Importer.new(options)
        importer.import_data(data)
        importer
      end

      def import_record(row, options = {})
        options.reverse_merge!(@default_import_options)
        importer = ActAsImportable::Importer.new(options)
        importer.import_record(row)
      end

    end
  end
end
