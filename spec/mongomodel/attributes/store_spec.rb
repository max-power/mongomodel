require 'spec_helper'
require 'active_support/core_ext/hash/indifferent_access'

require 'set'
require "ostruct"
require 'rational' unless RUBY_VERSION >= '1.9.2'

module MongoModel
  describe Attributes::Store do
    let(:properties) do
      properties = ActiveSupport::OrderedHash.new
      properties[:string]  = MongoModel::Properties::Property.new(:string, String)
      properties[:integer] = MongoModel::Properties::Property.new(:integer, Integer)
      properties[:float]   = MongoModel::Properties::Property.new(:float, Float)
      properties[:boolean] = MongoModel::Properties::Property.new(:boolean, Boolean)
      properties[:symbol]  = MongoModel::Properties::Property.new(:symbol, Symbol)
      properties[:hash]    = MongoModel::Properties::Property.new(:hash, Hash)
      properties[:array]   = MongoModel::Properties::Property.new(:array, Array)
      properties[:date]    = MongoModel::Properties::Property.new(:date, Date)
      properties[:time]    = MongoModel::Properties::Property.new(:time, Time)
      properties[:datetime] = MongoModel::Properties::Property.new(:datetime, DateTime)
      properties[:rational] = MongoModel::Properties::Property.new(:rational, Rational)
      properties[:openstruct] = MongoModel::Properties::Property.new(:openstruct, OpenStruct)
      properties[:custom]  = MongoModel::Properties::Property.new(:custom, CustomClass)
      properties[:custom_default] = MongoModel::Properties::Property.new(:custom_default, CustomClassWithDefault)
      properties[:default] = MongoModel::Properties::Property.new(:default, String, :default => 'Default')
      properties[:as]      = MongoModel::Properties::Property.new(:as, String, :as => '_custom_as')
      properties
    end
    let(:instance) { mock('instance', :properties => properties) }
    
    subject { Attributes::Store.new(instance) }
    
    it "sets default property values" do
      subject.keys.should == properties.keys
      subject[:default].should == 'Default'
    end
    
    it "sets default property value using mongomodel_default if defined by class" do
      subject[:custom_default].should == CustomClassWithDefault.new("Custom class default")
    end
    
    describe "setting to nil" do
      specify "all property types should be nullable" do
        properties.keys.each do |property|
          subject[property] = nil
          subject[property].should be_nil
        end
      end
    end
        
    it "sets attributes that aren't properties" do
      subject[:non_property] = "Hello World"
      subject[:non_property].should == "Hello World"
    end
        
    describe "type-casting" do
      TypeCastExamples = {
        :string =>
          {
            "abc" => "abc",
            123   => "123",
            nil   => nil
          },
        :integer =>
          {
            123      => 123,
            55.123   => 55,
            "999"    => 999,
            "12.123" => 12,
            "foo"    => nil,
            nil      => nil
          },
        :float =>
          {
            55.123   => 55.123,
            123      => 123.0,
            "12.123" => 12.123,
            "foo"    => nil,
            nil      => nil
          },
        :boolean =>
          {
            true    => true,
            false   => false,
            "true"  => true,
            "false" => false,
            "TRUE"  => true,
            "FALSE" => false,
            "yes"   => true,
            "no"    => false,
            "YES"   => true,
            "NO"    => false,
            "t"     => true,
            "f"     => false,
            "T"     => true,
            "F"     => false,
            "Y"     => true,
            "N"     => false,
            "y"     => true,
            "n"     => false,
            1       => true,
            0       => false,
            "1"     => true,
            "0"     => false,
            "foo"   => nil,
            ''      => nil,
            nil     => nil
          },
        :symbol =>
          {
            :some_symbol  => :some_symbol,
            "some_string" => :some_string,
            nil           => nil
          },
        :hash =>
          {
            { :foo => 'bar' } => { :foo => 'bar' }
          },
        :array =>
          {
            [123, 'abc', :foo, true] => [123, 'abc', :foo, true]
          },
        :date =>
          {
            Date.civil(2009, 11, 15)             => Date.civil(2009, 11, 15),
            Time.local(2008, 12, 3, 0, 0, 0, 0)  => Date.civil(2008, 12, 3),
            "2009/3/4"                           => Date.civil(2009, 3, 4),
            "Sat Jan 01 20:15:01 UTC 2000"       => Date.civil(2000, 1, 1),
            "2004-05-12"                         => Date.civil(2004, 5, 12),
            nil                                  => nil
          },
        :time =>
          {
            Time.local(2008, 5, 14, 1, 2, 3, 123456) => Time.local(2008, 5, 14, 1, 2, 3, 123000).in_time_zone,
            Date.civil(2009, 11, 15)                 => Time.local(2009, 11, 15, 0, 0, 0, 0).in_time_zone,
            "Sat Jan 01 20:15:01.123456 UTC 2000"    => Time.utc(2000, 1, 1, 20, 15, 1, 123000),
            "2009/3/4"                               => Time.zone.local(2009, 3, 4, 0, 0, 0, 0),
            "09:34"                                  => lambda { |t| t.hour == 9 && t.min == 34 },
            "5:21pm"                                 => lambda { |t| t.hour == 17 && t.min == 21 },
            { :date => "2005-11-04", :time => "4:55pm" } => Time.zone.local(2005, 11, 4, 16, 55, 0),
            nil                                      => nil
          },
        :datetime =>
          {
            Time.local(2008, 5, 14, 1, 2, 3, 123456) => Time.local(2008, 5, 14, 1, 2, 3, 0).to_datetime,
            Date.civil(2009, 11, 15)                 => DateTime.civil(2009, 11, 15, 0, 0, 0, 0),
            "Sat Jan 01 20:15:01.123456 UTC 2000"    => DateTime.civil(2000, 1, 1, 20, 15, 1, 0),
            "2009/3/4"                               => DateTime.civil(2009, 3, 4, 0, 0, 0, 0),
            "09:34"                                  => lambda { |t| t.hour == 9 && t.min == 34 },
            "5:21pm"                                 => lambda { |t| t.hour == 17 && t.min == 21 },
            { :date => "2005-11-04", :time => "4:55pm" } => DateTime.civil(2005, 11, 4, 16, 55, 0),
            nil                                      => nil
          },
        :rational =>
          {
            Rational(1, 15) => Rational(1, 15),
            "2/3"           => Rational(2, 3)
          },
        :openstruct =>
          {
            OpenStruct.new(:abc => 123) => OpenStruct.new(:abc => 123),
            { :mykey => "Hello world" } => OpenStruct.new(:mykey => "Hello world")
          }
      }
    
      TypeCastExamples.each do |type, examples|
        context "assigning to #{type} property" do
          examples.each do |assigned, expected|
            if expected.is_a?(Proc)
              it "casts #{assigned.inspect} to match proc" do
                subject[type] = assigned
                expected.call(subject[type]).should be_true
              end
            else
              it "casts #{assigned.inspect} to #{expected.inspect}" do
                subject[type] = assigned
                subject[type].should == expected
              end
            end
          end
        end
      end
    
      context "assigning to custom property" do
        before(:each) do
          @custom = CustomClass.new('instance name')
        end
      
        it "does not alter instances of CustomClass" do
          subject[:custom] = @custom
          subject[:custom].should == @custom
        end
      
        it "casts strings to CustomClass" do
          subject[:custom] = "foobar"
          subject[:custom].should == CustomClass.new('foobar')
        end
      end
    end
        
    describe "#before_type_cast" do
      BeforeTypeCastExamples = {
        :string => [ "abc", 123 ],
        :integer => [ 123, 55.123, "999", "12.123" ],
        :float => [ 55.123, 123, "12.123" ],
        :boolean => [ true, false, "true", "false", 1, 0, "1", "0", "" ],
        :symbol => [ :some_symbol, "some_string" ],
        :hash => [ { :foo => 'bar' } ],
        :array => [ [123, 'abc', :foo, true] ],
        :rational => [ "2/3" ],
        :openstruct => [ { :abc => 123 } ],
        :date => [ Date.civil(2009, 11, 15), Time.local(2008, 12, 3, 0, 0, 0, 0), "2009/3/4", "Sat Jan 01 20:15:01 UTC 2000" ],
        :time => [ Time.local(2008, 5, 14, 1, 2, 3, 4), Date.civil(2009, 11, 15), "Sat Jan 01 20:15:01 UTC 2000", "2009/3/4" ]
      }
    
      BeforeTypeCastExamples.each do |type, examples|
        context "assigning to #{type} property" do
          examples.each do |example|
            it "accesses pre-typecast value of #{example.inspect}" do
              subject[type] = example
              subject.before_type_cast(type).should == example
            end
          end
        end
      end
    end
        
    describe "#has?" do
      TrueExamples = {
        :string => [ 'abc', '1' ],
        :integer => [ -1, 1, 100 ],
        :float => [ 0.1, 44.123 ],
        :boolean => [ true, 1, "true" ],
        :symbol => [ :some_symbol ],
        :hash => [ { :foo => 'bar' } ],
        :array => [ [''], [123, 'abc', :foo, true] ],
        :date => [ Date.civil(2009, 11, 15) ],
        :time => [ Time.local(2008, 5, 14, 1, 2, 3, 4) ],
        :rational => [ Rational(2, 3) ],
        :openstruct => [ {} ],
        :custom => [ CustomClass.new('foobar'), 'baz' ]
      }
    
      FalseExamples = {
        :string => [ nil, '' ],
        :integer => [ nil, 0 ],
        :float => [ nil, 0.0 ],
        :boolean => [ nil, false, 0, "false" ],
        :symbol => [ nil, 0 ],
        :hash => [ nil, {} ],
        :array => [ [] ],
        :date => [ nil, '' ],
        :time => [ nil, '' ],
        :rational => [ nil ],
        :openstruct => [ nil ],
        :custom => [ nil ]
      }
    
      TrueExamples.each do |type, examples|
        context "assigning to #{type} property" do
          examples.each do |example|
            it "returns true for #{example.inspect}" do
              subject[type] = example
              subject.has?(type).should == true
            end
          end
        end
      end
    
      FalseExamples.each do |type, examples|
        context "assigning to #{type} property" do
          examples.each do |example|
            it "returns false for #{example.inspect}" do
              subject[type] = example
              subject.has?(type).should == false
            end
          end
        end
      end
    end
        
    describe "serialization" do
      it "converts to mongo representation" do
        subject[:string] = 'string'
        subject[:integer] = 42
        subject[:float] = 123.45
        subject[:boolean] = false
        subject[:symbol] = :symbol
        subject[:hash] = { :foo => 'bar', :custom => CustomClass.new('custom in hash') }
        subject[:array] = [ 123, 'abc', 45.67, true, :bar, CustomClass.new('custom in array') ]
        subject[:date] = Date.civil(2009, 11, 15)
        subject[:time] = Time.local(2008, 5, 14, 1, 2, 3, 4, 0.5)
        subject[:rational] = Rational(2, 3)
        subject[:openstruct] = OpenStruct.new(:abc => 123)
        subject[:custom] = CustomClass.new('custom')
        subject[:as] = "As property"
        subject[:non_property] = "Hello World"
        subject[:custom_non_property] = CustomClass.new('custom non property')
      
        subject.to_mongo.should include({
          'string' => 'string',
          'integer' => 42,
          'float' => 123.45,
          'boolean' => false,
          'symbol' => :symbol,
          'hash' => { :foo => 'bar', :custom => { :name => 'custom in hash' } },
          'array' => [ 123, 'abc', 45.67, true, :bar, { :name => 'custom in array' } ],
          'date' => "2009/11/15",
          'time' => Time.local(2008, 5, 14, 1, 2, 3, 4, 0),
          'rational' => "2/3",
          'openstruct' => { :abc => 123 },
          'custom' => { :name => 'custom' },
          '_custom_as' => "As property",
          'non_property' => "Hello World",
          'custom_non_property' => { :name => 'custom non property' },
        })
      end
    
      it "loads from mongo representation" do
        subject.from_mongo!({
          'string' => 'string',
          'integer' => 42,
          'float' => 123.45,
          'boolean' => false,
          'symbol' => :symbol,
          'hash' => { :foo => 'bar' },
          'array' => [ 123, 'abc', 45.67, true, :bar ],
          'date' => Time.utc(2009, 11, 15),
          'time' => Time.local(2008, 5, 14, 1, 2, 3, 4, 0.5),
          'rational' => "2/3",
          'openstruct' => { "foo" => "bar" },
          'custom' => { :name => 'custom' },
          '_custom_as' => "As property",
          'custom_non_property' => { :name => 'custom non property' }
        })
      
        subject[:string].should == 'string'
        subject[:integer].should == 42
        subject[:float].should == 123.45
        subject[:boolean].should == false
        subject[:symbol].should == :symbol
        subject[:hash].should == { :foo => 'bar' }.with_indifferent_access
        subject[:array].should == [ 123, 'abc', 45.67, true, :bar ]
        subject[:date].should == Date.civil(2009, 11, 15)
        subject[:time].should == Time.local(2008, 5, 14, 1, 2, 3, 4, 0)
        subject[:rational].should == Rational(2, 3)
        subject[:openstruct].should == OpenStruct.new(:foo => "bar")
        subject[:custom].should == CustomClass.new('custom')
        subject[:as].should == "As property"
        subject[:custom_non_property].should == { :name => 'custom non property' }
      end
    end
  end
end
