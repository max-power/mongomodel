require 'rubygems'
require 'bundler/setup'
Bundler.require

require 'rspec'

require 'mongomodel'

# Require spec helpers
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each { |f| require f }

require 'active_support/time'
Time.zone = "Australia/Melbourne"

RSpec.configure do |config|
  include SpecsFor
  include DefineClass
  
  config.before(:all) do
    MongoModel.configuration.use_database('mongomodel-specs')
  end
  
  config.before(:each) do
    MongoModel.database.collections.each { |c| c.drop rescue c.remove }
  end
end
