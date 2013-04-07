require 'csv'

module ActAsImportable
  class CSVImporter < ActAsImportable::Importer

    def import_csv_file(file)
      import_csv_text(File.read(file, options))
    end

    def import_csv_text(text)
      csv = ::CSV.parse(text, :headers => options[:headers] || true)
      csv.each do |row|
        import_record(row.to_hash)
      end
    end

  end
end