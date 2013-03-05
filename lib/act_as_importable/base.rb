require 'active_support'

module ActAsImportable::Base
  extend ActiveSupport::Concern

  module ClassMethods

    ##
    # Imports a data file into a model
    # Existing records are found by the :uid.
    # This can be changed by providing the :unique_identifier option or overriding the default_unique_identifier class method.
    def import_file(file, options = {})
      import_text(File.read(file), options)
    end

    ##
    # Imports csv text into a model
    def import_text(text, options = {})
      csv = ::CSV.parse(text, :headers => true)
      csv.each do |row|
        row = row.to_hash.with_indifferent_access
        import_record(row, options)
      end
    end

    def import_record(row, options = {})
      row = filter_columns(row, options)
      record = find_existing_record(row, options)
      remove_unique_identifiers(row, options) if record
      record ||= self.new()
      update_associations(record, row)
      record.update_attributes(row)
      record.save!
    end

    def filter_columns(row, options = {})
      row = row.reject { |key, value| Array(options[:except]).include? key } if options[:except]
      row = row.select { |key, value| Array(options[:only]).include? key } if options[:only]
      row
    end

    def remove_unique_identifiers(row, options = {})
      Array(options[:unique_identifier]).each do |field|
        row.delete(field)
      end
    end

    ##
    # Updates any associations specified in the import data.
    # Associations are specified in the header by separating the association and the field by a '.'
    def update_associations(existing, row)
      row.each_key do |key|
        key = key.to_s
        if key.include?('.')
          association_name = key.split('.').first
          field = key.split('.').last
          association = self.reflect_on_association(association_name.to_sym)
          association_value = association.klass.where("#{field} = ?", row[key]).first
          existing.send("#{association_name}=", association_value) if association_value
          row.delete(key)
        end
      end
    end

    ##
    # Fetches the existing record based on the identifier field(s) specified by the :unique_identifier option.
    # Defaults to the field specified by 'default_unique_identifier'
    def find_existing_record(row, options = {})
      return unless options[:unique_identifier]
      fields = Array(options[:unique_identifier])
      fields.inject(self.scoped.readonly(false)) { |scope, field|
        add_scope_for_field(scope, field.to_s, row)
      }.first
    end

    ##
    # Refines an existing scope to include a new field
    # The field can traverse 'belongs_to' associations by joining the association and field with a '.'
    # The query value should be found within the hash with the field as the key.
    # Notes: currently only supports field paths through one association.
    def add_scope_for_field(scope, field, hash)
      value = hash[field]
      return scope unless value
      if field.include?('.')
        association = field.split('.').first
        field_name = field.split('.').last
        scope.joins(association.to_sym).where("#{association.pluralize}.#{field_name} = ?", value)
      else
        scope.where("#{field} = ?", value)
      end
    end

  end

end
