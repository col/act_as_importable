module ActAsImportable
  class Importer

    def initialize(options = {})
      @default_options = options
      @imported_records = []
    end

    def options
      @default_options
    end

    def import_data(data)
      data.map do |row|
        import_record(row)
      end
    end

    def import_record(row)
      row = prepare_row_for_import(row)
      record = find_or_create_record(row)
      record.update_attributes(row)
      unless record.save
        Rails.logger.error(record.errors.full_messages)
      end
      imported_records << record
      record
    end

    def imported_records
      @imported_records ||= []
    end

    def successful_imports
      imported_records.select(&:valid?)
    end

    def failed_imports
      imported_records.reject(&:valid?)
    end

    def model_class
      options[:model_class]
    end

    def filter_columns(row)
      except = Array(options[:except]).map { |i| i.to_s }
      only = Array(options[:only]).map { |i| i.to_s }
      row.reject! { |key, value| except.include? key.to_s } if except.present?
      row.select! { |key, value| only.include? key.to_s } if only.present?
      row
    end

    private

    def prepare_row_for_import(row)
      row = row.with_indifferent_access
      add_default_values_to_row(row)
      convert_key_paths_to_values(row)
      filter_columns(row)
      row
    end

    def add_default_values_to_row(row)
      row.reverse_merge!(options[:default_values]) if options[:default_values]
    end

    def uid_values(row)
      Hash[Array(options[:uid]).map { |k| [k, row[k.to_sym]] }]
    end

    def remove_uid_values_from_row(row, options = {})
      Array(options[:uid]).each do |field|
        row.delete(field)
      end
    end

    def find_association_value_with_attribute(name, attribute)
      association = model_class.reflect_on_association(name.to_sym)
      association.klass.where(attribute).first
    end

    def find_or_create_record(row)
      record = find_or_create_by_uids(uid_values(row))
      remove_uid_values_from_row(row)
      record
    end

    def find_or_create_by_uids(attributes, &block)
      find_by_uids(attributes) || model_class.create(attributes, &block)
    end

    def find_by_uids(attributes)
      attributes.inject(model_class.scoped.readonly(false)) { |scope, key_value|
        add_scope_for_field(scope, key_value[0].to_s, key_value[1])
      }.first
    end

    def add_scope_for_field(scope, field, value)
      return scope unless value
      if (association = model_class.reflect_on_association(field.to_sym))
        field = association.foreign_key
        value = value.id
      end
      scope.where("#{model_class.table_name}.#{field} = ?", value)
    end

    # TODO: update this to support finding the association value with multiple columns
    def convert_key_paths_to_values(row)
      key_path_attributes = row.select { |k, v| k.to_s.include? '.' }
      key_path_attributes.each do |key, value|
        association_name, uid_field = key.to_s.split('.')
        row[association_name.to_sym] = find_association_value_with_attribute(association_name, uid_field => value)
        row.delete(key.to_sym)
      end
    end

  end
end