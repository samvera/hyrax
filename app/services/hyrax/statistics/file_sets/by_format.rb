module Hyrax
  module Statistics
    module FileSets
      class ByFormat < Statistics::TermQuery
        private

          # Returns 'file_format_sim'
          def index_key
            ActiveFedora.index_field_mapper.solr_name('file_format', :facetable)
          end
      end
    end
  end
end
