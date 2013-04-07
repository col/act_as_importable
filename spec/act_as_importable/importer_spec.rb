describe ActAsImportable::Importer do

  before(:each) do
    ActiveRecord::Base.connection.increment_open_transactions
    ActiveRecord::Base.connection.begin_db_transaction
  end

  after(:each) do
    ActiveRecord::Base.connection.rollback_db_transaction
    ActiveRecord::Base.connection.decrement_open_transactions
  end

  describe "#filter_columns" do
    let(:row) { {:name => 'Beer', :price => 2.5}.with_indifferent_access }

    it 'should filter columns when importing each record' do
      importer = ActAsImportable::Importer.new(:uid => :name, :model_class => Item)
      importer.should_receive(:filter_columns).with(row).and_return(row)
      importer.import_record(row)
    end

    it "should not modify row if no options provided" do
      importer = ActAsImportable::Importer.new
      importer.filter_columns(row).should == row
    end

    it "should remove columns specified by the :except option" do
      importer = ActAsImportable::Importer.new(:except => :price)
      importer.filter_columns(row).should == {'name' => 'Beer'}
    end

    it "should remove columns not specified by the :only option" do
      importer = ActAsImportable::Importer.new(:only => :price)
      importer.filter_columns(row).should == {'price' => 2.5}
    end
  end

end