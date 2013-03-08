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
        results = csv.map do |row|
          row = row.to_hash.with_indifferent_access
          import_record(row, options)
        end
      end

      # Creates or updates a model record
      # Existing records are found by the column(s) specified by the :uid option (default 'id').
      # If the values for the uid columns are not provided the row will be ignored.
      # If uid is set to nil it will import the row data as a new record.
      def import_record(row, options = {})
        options.reverse_merge!(@default_import_options)
        row.reverse_merge!(options[:default_values]) if options[:default_values]
        row = filter_columns(row, options)
        record = find_or_create_by_uid(uid_values(row, options))
        remove_uid_values_from_row(row, options)
        update_record(record, row)
        record.save!
      end

      def update_record(record, row)
        update_associations(record, row)
        record.update_attributes(row)
      end

      def filter_columns(row, options = {})
        row = row.reject { |key, value| Array(options[:except]).include? key } if options[:except]
        row = row.select { |key, value| Array(options[:only]).include? key } if options[:only]
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

      def update_associations(record, row)
        row.each_key do |key|
          key = key.to_s
          if key.include?('.')
            update_association(record, key, row[key])
            row.delete(key)
          end
        end
      end

      def update_association(record, key, value)
        association_name = key.split('.').first
        uid_field = key.split('.').last
        value = find_association_value_with_attribute(association_name, uid_field => value)
        record.send("#{association_name}=", value) if value
      end

      def find_association_value_with_attribute(name, attribute)
        association = self.reflect_on_association(name.to_sym)
        association.klass.where(attribute).first
      end

      # Note: This will be available by default in rails 4
      def find_or_create_by_uid(attributes, &block)
        find_by_uid(attributes) || create(attributes, &block)
      end

      def find_by_uid(attributes)
        attributes.inject(self.scoped.readonly(false)) { |scope, key_value|
          add_scope_for_field(scope, key_value[0].to_s, key_value[1])
        }.first
      end

      def add_scope_for_field(scope, field, value)
        return scope unless value
        if field.include?('.')
          association = field.split('.').first
          field_name = field.split('.').last
          scope.joins(association.to_sym).where("#{association.pluralize}.#{field_name} = ?", value)
        else
          scope.where("#{self.table_name}.#{field} = ?", value)
        end
      end

    end
  end
end
