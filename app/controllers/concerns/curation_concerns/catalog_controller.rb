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
    # This applies appropriate access controls to all solr queries
    Hydra::SearchBuilder.default_processor_chain += [:add_access_controls_to_solr_params, :filter_models]
  end

  module ClassMethods
    def t(*args)
      I18n.translate(*args)
    end

    def uploaded_field
      #  system_create_dtsi
      solr_name('date_uploaded', :stored_sortable, type: :date)
    end

    def modified_field
      solr_name('date_modified', :stored_sortable, type: :date)
    end

    def search_config
      { 'qf' => %w(title_tesim name_tesim), 'qt' => 'search', 'rows' => 10 }
    end
  end

  protected

    # Overriding Blacklight so that the search results can be displayed in a way compatible with
    # tokenInput javascript library.  This is used for suggesting "Related Works" to attach.
    def render_search_results_as_json
      { 'docs' => @response['response']['docs'].map { |solr_doc| serialize_work_from_solr(solr_doc) } }
    end

    def serialize_work_from_solr(solr_doc)
      title = solr_doc['title_tesim'].first
      title << " (#{solr_doc['human_readable_type_tesim'].first})" if solr_doc['human_readable_type_tesim'].present?
      {
        pid: solr_doc['id'],
        title: title
      }
    end
end
