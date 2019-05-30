
module Hyrax
  module Indexing
    class Solr
      def self.index_field_mapper
        @index_field_mapper ||= FieldMapper.new
      end
    end
  end
end
