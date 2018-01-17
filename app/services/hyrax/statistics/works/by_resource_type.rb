module Hyrax
  module Statistics
    module Works
      class ByResourceType < Statistics::TermQuery
        private

          def index_key
            'resource_type_ssim'
          end
      end
    end
  end
end
