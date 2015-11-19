module Hydra
  module PermissionsQuery
    extend ActiveSupport::Concern

    include Blacklight::AccessControls::PermissionsQuery

    # What type of solr document to create for the
    # Blacklight::AccessControls::PermissionsQuery.
    def permissions_document_class
      Hydra::PermissionsSolrDocument
    end

  end
end
