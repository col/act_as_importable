require 'active_support'

module ActAsImportable::Base
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
      options = options.reverse_merge!(@default_import_options)
      row = filter_columns(row, options)
      record = find_or_create_by(uid_values(row, options))
      remove_uid_values_from_row(row, options)
      update_record(record, row)
    end

    def update_record(record, row)
      update_associations(record, row)
      record.update_attributes(row)
      record.save!
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
    def find_or_create_by(attributes, &block)
      find_by(attributes) || create(attributes, &block)
    end

    # Note: This will by provided by default in rails 4
    def find_by(attributes)
      where(attributes).first
    end

  end

end
