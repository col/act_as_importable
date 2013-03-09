require 'active_support'
require 'csv'

module ActAsImportable
  module Base
    extend ActiveSupport::Concern

    module ClassMethods

      def import_csv_file(file, options = {})
        import_csv_text(File.read(file), options)
      end

      def import_csv_text(text, options = {})
        csv = ::CSV.parse(text, :headers => true)
        csv.map do |row|
          import_record(row.to_hash, options)
        end
      end

      # Creates or updates a model record
      # Existing records are found by the column(s) specified by the :uid option (default 'id').
      # If the values for the uid columns are not provided the row will be ignored.
      # If uid is set to nil it will import the row data as a new record.
      def import_record(row, options = {})
        options.reverse_merge!(@default_import_options)
        row = row.with_indifferent_access
        row.reverse_merge!(options[:default_values]) if options[:default_values]
        convert_key_paths_to_values!(row)
        row = filter_columns(row, options)
        record = find_or_create_by_uids(uid_values(row, options))
        remove_uid_values_from_row(row, options)
        record.update_attributes(row)
        record.save
        record
      end

      def filter_columns(row, options = {})
        except = Array(options[:except]).map { |i| i.to_s }
        only = Array(options[:only]).map { |i| i.to_s }
        row = row.reject { |key, value| except.include? key.to_s } if except.present?
        row = row.select { |key, value| only.include? key.to_s } if only.present?
        row
      end

      def uid_values(row, options)
        Hash[Array(options[:uid]).map { |k| [k, row[k.to_sym]] }]
      end

      def remove_uid_values_from_row(row, options = {})
        Array(options[:uid]).each do |field|
          row.delete(field)
        end
      end

      def find_association_value_with_attribute(name, attribute)
        association = self.reflect_on_association(name.to_sym)
        association.klass.where(attribute).first
      end

      def find_or_create_by_uids(attributes, &block)
        find_by_uids(attributes) || create(attributes, &block)
      end

      def find_by_uids(attributes)
        attributes.inject(self.scoped.readonly(false)) { |scope, key_value|
          add_scope_for_field(scope, key_value[0].to_s, key_value[1])
        }.first
      end

      def add_scope_for_field(scope, field, value)
        return scope unless value
        if (association = self.reflect_on_association(field.to_sym))
          field = association.foreign_key
          value = value.id
        end
        scope.where("#{self.table_name}.#{field} = ?", value)
      end

      # TODO: update this to support finding the association value with multiple columns
      def convert_key_paths_to_values!(row)
        key_path_attributes = row.select { |k,v| k.to_s.include? '.' }
        key_path_attributes.each do |key, value|
          association_name, uid_field = key.to_s.split('.')
          row[association_name.to_sym] = find_association_value_with_attribute(association_name, uid_field => value)
          row.delete(key.to_sym)
        end
      end

    end
  end
end
