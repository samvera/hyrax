# frozen_string_literal: true

module Hyrax
  ##
  # Indexes properties common to Hyrax::Resource types
  module ResourceIndexer
    def to_solr
      super.tap do |index_document|
        index_document[:has_model_ssim] = resource.class.name
        index_document[:alternate_ids_sim] = resource.alternate_ids.map(&:to_s)
      end
    end
  end
end
