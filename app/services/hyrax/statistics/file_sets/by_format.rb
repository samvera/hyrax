module Hyrax
  module Statistics
    module FileSets
      class ByFormat < Statistics::TermQuery
        private

          def index_key
            Hyrax::IndexMimeType.file_format_field
          end
      end
    end
  end
end
