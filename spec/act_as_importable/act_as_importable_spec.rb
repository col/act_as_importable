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
  act_as_importable

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

  it { should respond_to :import_file }
  it { should respond_to :import_text }
  it { should respond_to :import_record }

  describe "import csv file" do
    let(:file) { 'spec/fixtures/items.csv' }
    it 'should call import_text with context of file' do
      Item.should_receive(:import_text).with(File.read(file), {})
      Item.import_file(file)
    end
  end

  describe "import csv text" do
    let(:text) { "name,price\nBeer,2.5\nApple,0.5" }
    it 'should call import_record with row hashes' do
      Item.should_receive(:import_record).with({'name' => 'Beer', 'price' => '2.5'}, {}).once
      Item.should_receive(:import_record).with({'name' => 'Apple', 'price' => '0.5'}, {}).once
      Item.import_text(text)
    end
  end

  describe "import record" do
    let(:row) { {:name => 'Beer', :price => 2.5} }

    it 'should import an item' do
      expect { Item.import_record(row) }.to change{Item.count}.by(1)
    end

    describe "unique identifier" do
      before :each do
        @existing_item = Item.create!(:name => 'Beer', :price => 1.0)
      end
      it "should update an existing record with matching unique identifier" do
        Item.import_record(row, :unique_identifier => 'name')
        @existing_item.reload.price.should == 2.5
      end
      it "should not create a new item" do
        expect { Item.import_record(row, :unique_identifier => 'name') }.to change { Item.count }.by(0)
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

  describe "#filter_columns" do
    let(:row) { {:name => 'Beer', :price => 2.5} }

    it 'should filter columns when importing each record' do
      Item.should_receive(:filter_columns).with(row, {}).and_return(row)
      Item.import_record(row)
    end

    it "should not modify row if no options provided" do
      Item.filter_columns(row).should == {:name => 'Beer', :price => 2.5}
    end

    it "should remove columns specified by the :except option" do
      Item.filter_columns(row, :except => :price).should == {:name => 'Beer'}
    end

    it "should remove columns not specified by the :only option" do
      Item.filter_columns(row, :only => :price).should == {:price => 2.5}
    end
  end

end

