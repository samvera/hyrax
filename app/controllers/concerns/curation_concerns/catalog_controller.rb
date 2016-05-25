module CurationConcerns::CatalogController
  extend ActiveSupport::Concern
  include Hydra::Catalog
  # Extend Blacklight::Catalog with Hydra behaviors (primarily editing).
  include Hydra::Controller::ControllerBehavior
  include BreadcrumbsOnRails::ActionController
  include CurationConcerns::ThemedLayoutController

  included do
    with_themed_layout 'catalog'
    helper CurationConcerns::CatalogHelper
    # These before_filters apply the hydra access controls
    before_action :enforce_show_permissions, only: :show
  end

  module ClassMethods
    def uploaded_field
      #  system_create_dtsi
      solr_name('date_uploaded', :stored_sortable, type: :date)
    end

    def modified_field
      solr_name('date_modified', :stored_sortable, type: :date)
    end
  end
end
