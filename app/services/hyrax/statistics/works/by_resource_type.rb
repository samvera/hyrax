# frozen_string_literal: true
module Hyrax
  module Statistics
    module Works
      class ByResourceType < Statistics::TermQuery
        private

        def index_key
          "resource_type_sim"
        end
      end
    end
  end
end
