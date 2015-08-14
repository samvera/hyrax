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
    CatalogController.search_params_logic += [:add_access_controls_to_solr_params]
    self.search_params_logic += [:filter_models]
    self.search_params_logic += [:only_generic_files_and_curation_concerns]

    configure_blacklight do |config|
      config.search_builder_class = CurationConcerns::SearchBuilder
      ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
      config.default_solr_params = {
        qf: search_config['qf'],
        qt: search_config['qt'],
        rows: search_config['rows']
      }

      # solr field configuration for search results/index views
      config.index.title_field = solr_name('title', :stored_searchable)
      config.index.display_type_field = solr_name('has_model', :symbol)

      config.index.thumbnail_method = :thumbnail_tag
      config.index.partials.delete(:thumbnail) # we render this inside _index_default.html.erb

      # solr field configuration for document/show views
      # config.show.title_field = solr_name("title", :stored_searchable)
      # config.show.display_type_field = solr_name("has_model", :symbol)

      # solr fields that will be treated as facets by the blacklight application
      #   The ordering of the field names is the order of the display
      config.add_facet_field solr_name('human_readable_type', :facetable)
      config.add_facet_field solr_name('creator', :facetable), limit: 5
      config.add_facet_field solr_name('tag', :facetable), limit: 5
      config.add_facet_field solr_name('subject', :facetable), limit: 5
      config.add_facet_field solr_name('language', :facetable), limit: 5
      config.add_facet_field solr_name('based_near', :facetable), limit: 5
      config.add_facet_field solr_name('publisher', :facetable), limit: 5
      config.add_facet_field solr_name('file_format', :facetable), limit: 5
      config.add_facet_field 'generic_type_sim', show: false, single: true

      # Have BL send all facet field names to Solr, which has been the default
      # previously. Simply remove these lines if you'd rather use Solr request
      # handler defaults, or have no facets.
      config.add_facet_fields_to_solr_request!

      # solr fields to be displayed in the index (search results) view
      #   The ordering of the field names is the order of the display
      config.add_index_field solr_name('description', :stored_searchable)
      config.add_index_field solr_name('tag', :stored_searchable)
      config.add_index_field solr_name('subject', :stored_searchable)
      config.add_index_field solr_name('creator', :stored_searchable)
      config.add_index_field solr_name('contributor', :stored_searchable)
      config.add_index_field solr_name('publisher', :stored_searchable)
      config.add_index_field solr_name('based_near', :stored_searchable)
      config.add_index_field solr_name('language', :stored_searchable)
      config.add_index_field solr_name('date_uploaded', :stored_sortable)
      config.add_index_field solr_name('date_modified', :stored_sortable)
      config.add_index_field solr_name('date_created', :stored_searchable)
      config.add_index_field solr_name('rights', :stored_searchable)
      config.add_index_field solr_name('human_readable_type', :stored_searchable)
      config.add_index_field solr_name('format', :stored_searchable)
      config.add_index_field solr_name('identifier', :stored_searchable)

      # solr fields to be displayed in the show (single result) view
      #   The ordering of the field names is the order of the display
      config.add_show_field solr_name('title', :stored_searchable)
      config.add_show_field solr_name('description', :stored_searchable)
      config.add_show_field solr_name('tag', :stored_searchable)
      config.add_show_field solr_name('subject', :stored_searchable)
      config.add_show_field solr_name('creator', :stored_searchable)
      config.add_show_field solr_name('contributor', :stored_searchable)
      config.add_show_field solr_name('publisher', :stored_searchable)
      config.add_show_field solr_name('based_near', :stored_searchable)
      config.add_show_field solr_name('language', :stored_searchable)
      config.add_show_field solr_name('date_uploaded', :stored_sortable)
      config.add_show_field solr_name('date_modified', :stored_sortable)
      config.add_show_field solr_name('date_created', :stored_searchable)
      config.add_show_field solr_name('rights', :stored_searchable)
      config.add_show_field solr_name('human_readable_type', :stored_searchable)
      config.add_show_field solr_name('format', :stored_searchable)
      config.add_show_field solr_name('identifier', :stored_searchable)

      # "fielded" search configuration. Used by pulldown among other places.
      # For supported keys in hash, see rdoc for Blacklight::SearchFields
      #
      # Search fields will inherit the :qt solr request handler from
      # config[:default_solr_parameters], OR can specify a different one
      # with a :qt key/value. Below examples inherit, except for subject
      # that specifies the same :qt as default for our own internal
      # testing purposes.
      #
      # The :key is what will be used to identify this BL search field internally,
      # as well as in URLs -- so changing it after deployment may break bookmarked
      # urls.  A display label will be automatically calculated from the :key,
      # or can be specified manually to be different.
      #
      # This one uses all the defaults set by the solr request handler. Which
      # solr request handler? The one set in config[:default_solr_parameters][:qt],
      # since we aren't specifying it otherwise.
      config.add_search_field('all_fields', label: 'All Fields', include_in_advanced_search: false) do |field|
        title_name = solr_name('title', :stored_searchable, type: :string)
        label_name = solr_name('title', :stored_searchable, type: :string)
        contributor_name = solr_name('contributor', :stored_searchable, type: :string)
        field.solr_parameters = {
          qf: "#{title_name} #{label_name} file_format_tesim #{contributor_name}",
          pf: "#{title_name}"
        }
      end

      # Now we see how to over-ride Solr request handler defaults, in this
      # case for a BL "search field", which is really a dismax aggregate
      # of Solr search fields.
      # creator, title, description, publisher, date_created,
      # subject, language, resource_type, format, identifier, based_near,
      config.add_search_field('contributor') do |field|
        # solr_parameters hash are sent to Solr as ordinary url query params.

        # :solr_local_parameters will be sent using Solr LocalParams
        # syntax, as eg {! qf=$title_qf }. This is neccesary to use
        # Solr parameter de-referencing like $title_qf.
        # See: http://wiki.apache.org/solr/LocalParams
        solr_name = solr_name('contributor', :stored_searchable, type: :string)
        field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
        }
      end

      config.add_search_field('creator') do |field|
        solr_name = solr_name('creator', :stored_searchable, type: :string)
        field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
        }
      end

      config.add_search_field('title') do |field|
        solr_name = solr_name('title', :stored_searchable, type: :string)
        field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
        }
      end

      config.add_search_field('description') do |field|
        field.label = 'Abstract or Summary'
        solr_name = solr_name('description', :stored_searchable, type: :string)
        field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
        }
      end

      config.add_search_field('publisher') do |field|
        solr_name = solr_name('publisher', :stored_searchable, type: :string)
        field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
        }
      end

      config.add_search_field('date_created') do |field|
        solr_name = solr_name('created', :stored_searchable, type: :string)
        field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
        }
      end

      config.add_search_field('subject') do |field|
        solr_name = solr_name('subject', :stored_searchable, type: :string)
        field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
        }
      end

      config.add_search_field('language') do |field|
        solr_name = solr_name('language', :stored_searchable, type: :string)
        field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
        }
      end

      config.add_search_field('human_readable_type') do |field|
        solr_name = solr_name('human_readable_type', :stored_searchable, type: :string)
        field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
        }
      end

      config.add_search_field('format') do |field|
        field.include_in_advanced_search = false
        solr_name = solr_name('format', :stored_searchable, type: :string)
        field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
        }
      end

      config.add_search_field('identifier') do |field|
        field.include_in_advanced_search = false
        solr_name = solr_name('id', :stored_searchable, type: :string)
        field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
        }
      end

      config.add_search_field('based_near') do |field|
        field.label = 'Location'
        solr_name = solr_name('based_near', :stored_searchable, type: :string)
        field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
        }
      end

      config.add_search_field('tag') do |field|
        solr_name = solr_name('tag', :stored_searchable, type: :string)
        field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
        }
      end

      config.add_search_field('depositor') do |field|
        solr_name = solr_name('depositor', :stored_searchable, type: :string)
        field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
        }
      end

      config.add_search_field('rights') do |field|
        solr_name = solr_name('rights', :stored_searchable, type: :string)
        field.solr_local_parameters = {
          qf: solr_name,
          pf: solr_name
        }
      end

      # "sort results by" select (pulldown)
      # label in pulldown is followed by the name of the SOLR field to sort by and
      # whether the sort is ascending or descending (it must be asc or desc
      # except in the relevancy case).
      # label is key, solr field is value
      config.add_sort_field "score desc, #{uploaded_field} desc", label: "relevance \u25BC"
      config.add_sort_field "#{uploaded_field} desc", label: "date uploaded \u25BC"
      config.add_sort_field "#{uploaded_field} asc", label: "date uploaded \u25B2"
      config.add_sort_field "#{modified_field} desc", label: "date modified \u25BC"
      config.add_sort_field "#{modified_field} asc", label: "date modified \u25B2"

      # If there are more than this many search results, no spelling ("did you
      # mean") suggestion is offered.
      config.spell_max = 5
    end
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

    def depositor
      # Hydra.config[:permissions][:owner] maybe it should match this config variable, but it doesn't.
      Solrizer.solr_name('depositor', :stored_searchable, type: :string)
    end

    def sort_field
      "#{Solrizer.solr_name('system_create', :sortable)} desc"
    end
end
