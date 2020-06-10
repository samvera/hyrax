# frozen_string_literal: true
module Hyrax
  module UrlHelper
    # generated models get registered as curation concerns and need a
    # track_model_path to render Blacklight-related views
    (['FileSet', 'Collection'] + Hyrax.config.registered_curation_concern_types).each do |concern|
      define_method("track_#{concern.constantize.model_name.singular_route_key}_path") { |*args| main_app.track_solr_document_path(*args) }
    end
  end
end
