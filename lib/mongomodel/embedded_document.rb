module MongoModel
  class EmbeddedDocument
    def ==(other)
      other.is_a?(self.class) && other.attributes == attributes
    end
    
    include Attributes
    include MultiParameterAttributes
    include Properties
    
    include Translation
    include Validations
    include Callbacks
    
    include Associations
    
    include AttributeMethods
    include AttributeMethods::Read
    include AttributeMethods::Write
    include AttributeMethods::Query
    include AttributeMethods::BeforeTypeCast
    include AttributeMethods::Protected
    include AttributeMethods::Dirty
    
    include Logging
    include RecordStatus
    include ActiveModelCompatibility
    include Serialization
    include Timestamps
    include PrettyInspect
    include AbstractClass
    include DocumentParent
    
    # Allow Collection class to be used in property definitions
    Collection = MongoModel::Collection
    extend Collection::PropertyDefaults
    
    # Allow Map class to be used in property definitions
    Map = MongoModel::Map
    extend Map::PropertyDefaults
    
    undef_method :type if method_defined?(:type)
    property :type, String, :as => '_type', :default => lambda { |doc| doc.class.name }, :protected => true
    
    self.abstract_class = true
  end
end
