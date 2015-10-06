module CurationConcerns
  module FileSet
    module FullTextIndexing
      extend ActiveSupport::Concern

      included do
        contains 'full_text'
      end
    end
  end
end
