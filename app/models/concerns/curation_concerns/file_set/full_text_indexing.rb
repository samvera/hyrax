module CurationConcerns
  module FileSet
    module FullTextIndexing
      extend ActiveSupport::Concern

      included do
        has_subresource 'full_text'
      end
    end
  end
end
