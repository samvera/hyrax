# frozen_string_literal: true

module Hyrax
  ##
  # Indexes properties common to Hryax::Resource types
  module ResourceIndexer
    def to_solr
      super.tap do |index_document|
        index_document[:alternate_ids_sm] = resource.alternate_ids.map(&:to_s)
      end
    end
  end
end
