require 'active_support'
require 'active_model'

require 'mongo'

require 'mongomodel/support/core_extensions'
require 'mongomodel/support/exceptions'
require 'mongomodel/version'

require 'active_support/core_ext/module/attribute_accessors'

module MongoModel
  autoload :Document,         'mongomodel/document'
  autoload :EmbeddedDocument, 'mongomodel/embedded_document'
  
  autoload :Properties,       'mongomodel/concerns/properties'
  autoload :Attributes,       'mongomodel/concerns/attributes'
  autoload :AttributeMethods, 'mongomodel/concerns/attribute_methods'
  autoload :Associations,     'mongomodel/concerns/associations'
  autoload :Translation,      'mongomodel/concerns/translation'
  autoload :Validations,      'mongomodel/concerns/validations'
  autoload :Callbacks,        'mongomodel/concerns/callbacks'
  autoload :Serialization,    'mongomodel/concerns/serialization'
  autoload :Logging,          'mongomodel/concerns/logging'
  autoload :Timestamps,       'mongomodel/concerns/timestamps'
  autoload :PrettyInspect,    'mongomodel/concerns/pretty_inspect'
  autoload :RecordStatus,     'mongomodel/concerns/record_status'
  autoload :AbstractClass,    'mongomodel/concerns/abstract_class'
  autoload :ActiveModelCompatibility, 'mongomodel/concerns/activemodel'
  
  autoload :MongoOptions,     'mongomodel/support/mongo_options'
  autoload :MongoOrder,       'mongomodel/support/mongo_order'
  autoload :MongoOperator,    'mongomodel/support/mongo_operator'
  autoload :Types,            'mongomodel/support/types'
  autoload :Configuration,    'mongomodel/support/configuration'
  
  autoload :Collection,       'mongomodel/support/collection'
  
  module AttributeMethods
    autoload :Read,           'mongomodel/concerns/attribute_methods/read'
    autoload :Write,          'mongomodel/concerns/attribute_methods/write'
    autoload :Query,          'mongomodel/concerns/attribute_methods/query'
    autoload :BeforeTypeCast, 'mongomodel/concerns/attribute_methods/before_type_cast'
    autoload :Protected,      'mongomodel/concerns/attribute_methods/protected'
    autoload :Dirty,          'mongomodel/concerns/attribute_methods/dirty'
  end
  
  module Attributes
    autoload :Store,          'mongomodel/attributes/store'
    autoload :Typecasting,    'mongomodel/attributes/typecasting'
    autoload :Mongo,          'mongomodel/attributes/mongo'
  end
  
  module Associations
    module Base
      autoload :Definition,   'mongomodel/concerns/associations/base/definition'
      autoload :Association,  'mongomodel/concerns/associations/base/association'
      autoload :Proxy,        'mongomodel/concerns/associations/base/proxy'
    end
    
    autoload :BelongsTo,           'mongomodel/concerns/associations/belongs_to'
    autoload :HasManyByIds,        'mongomodel/concerns/associations/has_many_by_ids'
    autoload :HasManyByForeignKey, 'mongomodel/concerns/associations/has_many_by_foreign_key'
  end
  
  module DocumentExtensions
    autoload :Persistence,       'mongomodel/document/persistence'
    autoload :OptimisticLocking, 'mongomodel/document/optimistic_locking'
    autoload :Finders,           'mongomodel/document/finders'
    autoload :DynamicFinders,    'mongomodel/document/dynamic_finders'
    autoload :Indexes,           'mongomodel/document/indexes'
    autoload :Scopes,            'mongomodel/document/scopes'
    autoload :Scope,             'mongomodel/document/scopes'
    autoload :Validations,       'mongomodel/document/validations'
    autoload :Callbacks,         'mongomodel/document/callbacks'
  end
  
  mattr_accessor :logger
  
  def self.configuration
    @_configuration ||= Configuration.defaults
  end
  
  def self.configuration=(config)
    @_database = nil
    @_configuration = Configuration.new(config)
  end
  
  def self.database
    @_database ||= configuration.establish_connection
  end
end

I18n.load_path << File.dirname(__FILE__) + '/mongomodel/locale/en.yml'
