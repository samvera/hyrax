module Sufia
  module Statistics
    module FileSets
      class ByFormat < Statistics::TermQuery
        private

          # Returns 'file_format_sim'
          def index_key
            Solrizer.solr_name('file_format', Solrizer::Descriptor.new(:string, :indexed, :multivalued))
          end
      end
    end
  end
end
