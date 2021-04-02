# frozen_string_literal: true
module Hyrax
  module UrlHelper
    # generated models get registered as curation concerns and need a
    # track_model_path to render Blacklight-related views
    (['FileSet', 'Collection'] + Hyrax.config.registered_curation_concern_types).each do |concern|
      model = concern.safe_constantize
      model_name = model.respond_to?(:model_name) && model.model_name
      next unless model_name
      define_method("track_#{model_name.singular_route_key}_path") { |*args| main_app.track_solr_document_path(*args) }
    end
  end
end
