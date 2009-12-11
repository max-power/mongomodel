require 'active_support/core_ext/module/aliasing'
require 'active_support/core_ext/class/removal'

module MongoModel
  module Attributes
    extend ActiveSupport::Concern
    
    included do
      alias_method_chain :initialize, :attributes
    end
    
    def initialize_with_attributes(attrs={})
      initialize_without_attributes
      
      self.attributes = attrs
      yield self if block_given?
    end
    
    def attributes
      @attributes ||= initialize_attribute_store
    end
    
    def attributes=(attrs)
      attrs.each do |attr, value|
        if respond_to?("#{attr}=")
          send("#{attr}=", value)
        else
          write_attribute(attr, value)
        end
      end
    end
    
    def freeze
      attributes.freeze; self
    end
    
    def frozen?
      attributes.frozen?
    end
    
    def to_mongo
      attributes.to_mongo
    end
    
    def embedded_documents
      attributes.values.select { |attr| attr.is_a?(EmbeddedDocument) }
    end
    
    module ClassMethods
      def from_mongo(hash)
        doc = class_for_type(hash['_type']).new
        doc.attributes.from_mongo!(hash)
        doc
      end
    
    private
      def class_for_type(type)
        type = type.constantize
        
        if (subclasses + [name]).include?(type.to_s)
          type
        else
          raise DocumentNotFound, "Document not of the correct type"
        end
      rescue NameError
        self
      end
    end
    
  private
    def initialize_attribute_store
      attributes = Attributes::Store.new(properties)
      attributes.set_defaults!(self)
      attributes
    end
  end
end
