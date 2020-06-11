# frozen_string_literal: true
module Hyrax
  module Statistics
    module FileSets
      class ByFormat < Statistics::TermQuery
        private

        # Returns 'file_format_sim'
        def index_key
          "file_format_sim"
        end
      end
    end
  end
end
