require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

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

  describe "delete_missing_records option" do
    let(:importer) { ActAsImportable::Importer.new(:uid => :name, :model_class => Item, :delete_missing_records => true) }
    let(:beer_category) { Category.create!(:name => 'Beer') }
    let(:wine_category) { Category.create!(:name => 'Wine') }

    before :each do
      @beer1 = Item.create!(:name => 'Beer 1', :price => 3.0, :category => beer_category)
      @beer2 = Item.create!(:name => 'Beer 2', :price => 3.5, :category => beer_category)
      @wine1 = Item.create!(:name => 'Wine 1', :price => 16.5, :category => wine_category)
    end

    it "should call delete_missing_records when the option is true" do
      importer.options[:delete_missing_records] = true
      importer.should_receive(:delete_missing_records).once
      importer.import_data([{:name => 'Beer 1', :price => 3.0}])
    end

    it "should not call delete_missing_records when the option is false" do
      importer.options[:delete_missing_records] = false
      importer.should_not_receive(:delete_missing_records)
      importer.import_data([{:name => 'Beer 1', :price => 3.0}])
    end

    it "should default the delete_missing_records option to false" do
      importer.options.delete(:delete_missing_records)
      importer.should_not_receive(:delete_missing_records)
      importer.import_data([{:name => 'Beer 1', :price => 3.0}])
    end

    context "when no existing_record_scope option is provided" do

      it "should delete all existing records that were not included in the import" do
        expect {
          importer.import_data([{:name => 'Beer 1', :price => 3.0}])
        }.to change { Item.count }.from(3).to(1)
      end

    end

    context "when an existing_record_scope option is provided" do

      before :each do
        importer.options[:existing_record_scope] = Item.for_category(beer_category)
      end

      it "should not delete any records when all objects in the existing_records_scope are updated" do
        expect {
          importer.import_data([{:name => 'Beer 1', :price => 3.0}, {:name => 'Beer 2', :price => 3.0}])
        }.to change { Item.count }.by(0)
      end

      it "should delete existing records, in the scope provided, that were not included in the import" do
        expect {
          importer.import_data([{:name => 'Beer 1', :price => 3.0}])
        }.to change { Item.count }.from(3).to(2)
      end

    end

  end

end