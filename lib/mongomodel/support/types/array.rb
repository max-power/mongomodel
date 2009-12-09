module MongoModel
  module Types
    class Array < Object
      def to_mongo(array)
        array.map { |i|
          Types.converter_for(i.class).to_mongo(i)
        }
      end
    end
  end
end