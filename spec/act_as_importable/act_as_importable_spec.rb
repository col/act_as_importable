require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# create the tables for the tests
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'categories'")
ActiveRecord::Base.connection.create_table(:categories) do |t|
  t.string :name
end

class Category < ActiveRecord::Base
  has_many :items
end

ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS 'items'")
ActiveRecord::Base.connection.create_table(:items) do |t|
  t.integer :category_id
  t.string :name
  t.float :price
end

class Item < ActiveRecord::Base
  # This line isn't needed in a real Rails app.
  include ActAsImportable::Config

  act_as_importable :uid => 'name'

  belongs_to :category
end

describe "an act_as_importable model" do

  before(:each) do
    ActiveRecord::Base.connection.increment_open_transactions
    ActiveRecord::Base.connection.begin_db_transaction
  end

  after(:each) do
    ActiveRecord::Base.connection.rollback_db_transaction
    ActiveRecord::Base.connection.decrement_open_transactions
  end

  subject { Item }

  it { should respond_to :import_csv_file }
  it { should respond_to :import_csv_text }
  it { should respond_to :import_record }
  it { should respond_to :default_import_options }

  let(:default_options) { {:uid => 'name'} }

  it "should have the correct default import options" do
    Item.default_import_options.should == default_options
  end

  describe "import csv file" do
    let(:file) { 'spec/fixtures/items.csv' }
    it 'should call import_text with contents of file' do
      Item.should_receive(:import_csv_text).with(File.read(file), {})
      Item.import_csv_file(file)
    end
  end

  describe "import csv text" do
    let(:text) { "name,price\nBeer,2.5\nApple,0.5" }
    it 'should call import_record with row hashes' do
      Item.should_receive(:import_record).with({'name' => 'Beer', 'price' => '2.5'}, {}).once
      Item.should_receive(:import_record).with({'name' => 'Apple', 'price' => '0.5'}, {}).once
      Item.import_csv_text(text)
    end
  end

  describe "import record" do
    let(:row) { {:name => 'Beer', :price => 2.5} }

    it 'should import an item' do
      expect { Item.import_record(row) }.to change{Item.count}.by(1)
    end

    describe "unique identifier (uid) option" do

      context "record exists with matching uid" do
        before :each do
          @existing_item = Item.create!(:name => 'Beer', :price => 1.0)
        end
        it "should update an existing record with matching uid" do
          Item.import_record(row, :uid => :name)
          @existing_item.reload.price.should == 2.5
        end
        it "should not create a new item" do
          expect { Item.import_record(row, :uid => 'name') }.to change { Item.count }.by(0)
        end
      end

      context "record doesn't exist with matching uid" do
        it "should create a new record" do
          expect { Item.import_record(row, :uid => :name) }.to change { Item.count }.by(1)
        end
        it "should assign the uid values to the record" do
          Item.import_record(row, :uid => :name)
          Item.first.name.should == 'Beer'
        end
      end

      context "support for multiple uid columns" do
        let(:category1) { Category.create!(:name => 'Beverage') }
        let(:category2) { Category.create!(:name => 'Beers') }
        let(:row) { { :name => 'Beer', :'category.name' => category2.name, :price => 3.2}}
        before :each do
          @existing1 = Item.create!(:name => 'Beer', :price => 1.0, :category => category1)
          @existing2 = Item.create!(:name => 'Beer', :price => 2.5, :category => category2)
        end

        it "should match existing records with multiple uid columns" do
          Item.import_record(row, :uid => [:name, :category])
          @existing2.reload.price.should == 3.2
        end

        it "should allow uid column value to come from default values" do
          row = { :name => 'Beer', :price => 3.2 }
          Item.import_record(row, :uid => [:name, :category], :default_values => { :'category.name' => category2.name })
          @existing2.reload.price.should == 3.2
        end

      end

    end
  end

  describe "import record with association" do
    let(:row) { {:name => 'Beer', :price => 2.5, 'category.name' => 'Beverage'} }
    before :each do
      @category = Category.create!(:name => 'Beverage')
    end
    it "should import item with a category" do
      Item.import_record(row)
      Item.first.category.should == @category
    end
  end

  describe "default_values option" do
    let(:row) { {:name => 'Beer'} }

    it "should assign default values to new record" do
      Item.import_record(row, :default_values => { :price => 3.2 })
      Item.first.price.should == 3.2
    end

    it "should assign default values to updated record" do
      Item.create!(:name => 'Beer', :price => 1.0)
      Item.import_record(row, :uid => :name, :default_values => {:price => 3.2})
      Item.first.price.should == 3.2
    end

    it "should not override row values" do
      row[:price] = 4.1
      Item.import_record(row, :default_values => {:price => 3.2})
      Item.first.price.should == 4.1
    end

    describe "associations" do
      let(:category) { Category.new(:name => 'Beverage') }

      it "should assign default association value to new record" do
        Item.import_record(row, :default_values => {:category => category})
        Item.first.category.should == category
      end

      it "should assign default association value to updated record" do
        Item.create!(:name => 'Beer', :price => 1.0)
        Item.import_record(row, :uid => :name, :default_values => {:category => category})
        Item.first.category.should == category
      end

      it "should not override row values" do
        other_category = Category.create!(:name => 'Food & Beverage')
        row['category.name'] = other_category.name
        Item.import_record(row, :default_values => {'category.name' => category.name})
        Item.first.category.should == other_category
      end
    end

  end

  describe "#filter_columns" do
    let(:row) { {:name => 'Beer', :price => 2.5}.with_indifferent_access }

    it 'should filter columns when importing each record' do
      Item.should_receive(:filter_columns).with(row, default_options).and_return(row)
      Item.import_record(row)
    end

    it "should not modify row if no options provided" do
      Item.filter_columns(row).should == row
    end

    it "should remove columns specified by the :except option" do
      Item.filter_columns(row, :except => :price).should == {'name' => 'Beer'}
    end

    it "should remove columns not specified by the :only option" do
      Item.filter_columns(row, :only => :price).should == {'price' => 2.5}
    end
  end

end

