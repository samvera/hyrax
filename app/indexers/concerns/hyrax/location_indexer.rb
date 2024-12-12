# frozen_string_literal: true

module Hyrax
  ##
  # Indexes properties common to Hyrax::Resource types
  module LocationIndexer
    def to_solr
      super.tap do |index_document|
        index_document[:based_near_label_tesim] = index_document[:based_near_label_sim] = based_near_label_lookup(resource.based_near) if resource.respond_to? :based_near
      end
    end

    private

    def based_near_label_lookup(locations)
      locations.map do |loc|
        location_service.full_label(loc) if loc.present?
      end
    end

    def location_service
      Hyrax.config.location_service
    end
  end
end
