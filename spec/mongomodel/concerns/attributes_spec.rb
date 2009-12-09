require 'spec_helper'
require 'active_support/core_ext/hash/indifferent_access'

module MongoModel
  AttributeTypes = {
    String => "my string",
    Integer => 99,
    Float => 45.123,
    Symbol => :foobar,
    Boolean => false,
    Array => [ 1, 2, 3, "hello", :world, [99, 100] ],
    Hash => { :rabbit => 'hat', 'hello' => 12345 }.with_indifferent_access,
    Date => Date.today,
    Time => Time.now,
    CustomClass => CustomClass.new('hello')
  }
  
  specs_for(Document, EmbeddedDocument) do
    AttributeTypes.each do |type, value|
      describe "setting #{type} attributes" do
        define_class(:TestDocument, described_class) do
          property :test_property, type
        end
        
        if specing?(EmbeddedDocument)
          define_class(:ParentDocument, Document) do
            property :child, TestDocument
          end
          
          let(:parent) { ParentDocument.create!(:child => TestDocument.new(:test_property => value)) }
          let(:child) { parent.child }
          let(:reloaded) { ParentDocument.find(parent.id).child }
          
          subject { child }
        else
          subject { TestDocument.create!(:test_property => value) }
          
          let(:reloaded) { TestDocument.find(subject.id) }
        end
        
        it "should read the correct value from attributes" do
          subject.test_property.should == value
        end
      
        it "should read the correct value after reloading" do
          reloaded.test_property.should == subject.test_property
        end
      end
    end
    
    describe "setting attributes with hash" do
      define_class(:TestDocument, described_class) do
        property :test_property, String
        
        def test_property=(value)
          write_attribute(:test_property, 'set from method')
        end
      end
      
      subject { TestDocument.new }
      
      it "should call custom property methods" do
        subject.attributes = { :test_property => 'property value' }
        subject.test_property.should == 'set from method'
      end
      
      it "should use write_attribute if no such property" do
        subject.attributes = { :non_property => 'property value' }
        subject.read_attribute(:non_property).should == 'property value'
      end
    end
    
    describe "#new" do
      define_class(:TestDocument, described_class)
      
      it "should yield the instance to a block if provided" do
        block_called = false
        
        TestDocument.new do |doc|
          block_called = true
          doc.should be_an_instance_of(TestDocument)
        end
        
        block_called.should be_true
      end
    end
    
    context "a frozen instance" do
      define_class(:TestDocument, described_class) do
        property :test_property, String
      end
      
      subject { TestDocument.new(:test_property => 'Test') }
      
      before(:each) { subject.freeze }
      
      it { should be_frozen }
      
      it "should not allow changes to the attributes hash" do
        lambda { subject.attributes[:test_property] = 'Change' }.should raise_error
      end
    end
  end
end