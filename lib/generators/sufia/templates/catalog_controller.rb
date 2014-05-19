# -*- coding: utf-8 -*-
# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
require 'blacklight_advanced_search'

# bl_advanced_search 1.2.4 is doing unitialized constant on these because we're calling ParseBasicQ directly
require 'parslet'
require 'parsing_nesting/tree'

class CatalogController < ApplicationController
  include Blacklight::Catalog
  # Extend Blacklight::Catalog with Hydra behaviors (primarily editing).
  include Hydra::Controller::ControllerBehavior
  include BlacklightAdvancedSearch::ParseBasicQ
  include Sufia::Catalog

  # These before_filters apply the hydra access controls
  before_filter :enforce_show_permissions, only: :show
  # This applies appropriate access controls to all solr queries
  CatalogController.solr_search_params_logic += [:add_access_controls_to_solr_params]

  skip_before_filter :default_html_head

  def self.uploaded_field
    solr_name('desc_metadata__date_uploaded', :stored_sortable, type: :date)
  end

  def self.modified_field
    solr_name('desc_metadata__date_modified', :stored_sortable, type: :date)
  end

  configure_blacklight do |config|
    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      qt: "search",
      rows: 10
    }

    # Specify which field to use in the tag cloud on the homepage.
    # To disable the tag cloud, comment out this line.
    config.tag_cloud_field_name = Solrizer.solr_name("desc_metadata__tag", :facetable)

    # solr field configuration for document/show views
    config.index.title_field = solr_name("desc_metadata__title", :stored_searchable)
    config.index.display_type_field = solr_name("has_model", :symbol)
    config.index.thumbnail_method = :sufia_thumbnail_tag

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    config.add_facet_field solr_name("desc_metadata__resource_type", :facetable), label: "Resource Type", limit: 5
    config.add_facet_field solr_name("desc_metadata__creator", :facetable), label: "Creator", limit: 5
    config.add_facet_field solr_name("desc_metadata__tag", :facetable), label: "Keyword", limit: 5
    config.add_facet_field solr_name("desc_metadata__subject", :facetable), label: "Subject", limit: 5
    config.add_facet_field solr_name("desc_metadata__language", :facetable), label: "Language", limit: 5
    config.add_facet_field solr_name("desc_metadata__based_near", :facetable), label: "Location", limit: 5
    config.add_facet_field solr_name("desc_metadata__publisher", :facetable), label: "Publisher", limit: 5
    config.add_facet_field solr_name("file_format", :facetable), label: "File Format", limit: 5

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field solr_name("desc_metadata__title", :stored_searchable), label: "Title", itemprop: 'name'
    config.add_index_field solr_name("desc_metadata__description", :stored_searchable), label: "Description", itemprop: 'description'
    config.add_index_field solr_name("desc_metadata__tag", :stored_searchable), label: "Keyword", itemprop: 'keywords'
    config.add_index_field solr_name("desc_metadata__subject", :stored_searchable), label: "Subject", itemprop: 'about'
    config.add_index_field solr_name("desc_metadata__creator", :stored_searchable), label: "Creator", itemprop: 'creator'
    config.add_index_field solr_name("desc_metadata__contributor", :stored_searchable), label: "Contributor", itemprop: 'contributor'
    config.add_index_field solr_name("desc_metadata__publisher", :stored_searchable), label: "Publisher", itemprop: 'publisher'
    config.add_index_field solr_name("desc_metadata__based_near", :stored_searchable), label: "Location", itemprop: 'contentLocation'
    config.add_index_field solr_name("desc_metadata__language", :stored_searchable), label: "Language", itemprop: 'inLanguage'
    config.add_index_field solr_name("desc_metadata__date_uploaded", :stored_searchable), label: "Date Uploaded", itemprop: 'datePublished'
    config.add_index_field solr_name("desc_metadata__date_modified", :stored_searchable), label: "Date Modified", itemprop: 'dateModified'
    config.add_index_field solr_name("desc_metadata__date_created", :stored_searchable), label: "Date Created", itemprop: 'dateCreated'
    config.add_index_field solr_name("desc_metadata__rights", :stored_searchable), label: "Rights"
    config.add_index_field solr_name("desc_metadata__resource_type", :stored_searchable), label: "Resource Type"
    config.add_index_field solr_name("desc_metadata__format", :stored_searchable), label: "File Format"
    config.add_index_field solr_name("desc_metadata__identifier", :stored_searchable), label: "Identifier"

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field solr_name("desc_metadata__title", :stored_searchable), label: "Title"
    config.add_show_field solr_name("desc_metadata__description", :stored_searchable), label: "Description"
    config.add_show_field solr_name("desc_metadata__tag", :stored_searchable), label: "Keyword"
    config.add_show_field solr_name("desc_metadata__subject", :stored_searchable), label: "Subject"
    config.add_show_field solr_name("desc_metadata__creator", :stored_searchable), label: "Creator"
    config.add_show_field solr_name("desc_metadata__contributor", :stored_searchable), label: "Contributor"
    config.add_show_field solr_name("desc_metadata__publisher", :stored_searchable), label: "Publisher"
    config.add_show_field solr_name("desc_metadata__based_near", :stored_searchable), label: "Location"
    config.add_show_field solr_name("desc_metadata__language", :stored_searchable), label: "Language"
    config.add_show_field solr_name("desc_metadata__date_uploaded", :stored_searchable), label: "Date Uploaded"
    config.add_show_field solr_name("desc_metadata__date_modified", :stored_searchable), label: "Date Modified"
    config.add_show_field solr_name("desc_metadata__date_created", :stored_searchable), label: "Date Created"
    config.add_show_field solr_name("desc_metadata__rights", :stored_searchable), label: "Rights"
    config.add_show_field solr_name("desc_metadata__resource_type", :stored_searchable), label: "Resource Type"
    config.add_show_field solr_name("desc_metadata__format", :stored_searchable), label: "File Format"
    config.add_show_field solr_name("desc_metadata__identifier", :stored_searchable), label: "Identifier"

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
      all_names = config.show_fields.values.map{|val| val.field}.join(" ")
      title_name = solr_name("desc_metadata__title", :stored_searchable)
      field.solr_parameters = {
        qf: "#{all_names} noid_tsi file_format_tesim",
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
      field.solr_parameters = { :"spellcheck.dictionary" => "contributor" }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      solr_name = solr_name("desc_metadata__contributor", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('creator') do |field|
      field.solr_parameters = { :"spellcheck.dictionary" => "creator" }
      solr_name = solr_name("desc_metadata__creator", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('title') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "title"
      }
      solr_name = solr_name("desc_metadata__title", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('description') do |field|
      field.label = "Abstract or Summary"
      field.solr_parameters = {
        :"spellcheck.dictionary" => "description"
      }
      solr_name = solr_name("desc_metadata__description", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('publisher') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "publisher"
      }
      solr_name = solr_name("desc_metadata__publisher", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('date_created') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "date_created"
      }
      solr_name = solr_name("desc_metadata__created", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('subject') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "subject"
      }
      solr_name = solr_name("desc_metadata__subject", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('language') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "language"
      }
      solr_name = solr_name("desc_metadata__language", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('resource_type') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "resource_type"
      }
      solr_name = solr_name("desc_metadata__resource_type", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('format') do |field|
      field.include_in_advanced_search = false
      field.solr_parameters = {
        :"spellcheck.dictionary" => "format"
      }
      solr_name = solr_name("desc_metadata__format", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('identifier') do |field|
      field.include_in_advanced_search = false
      field.solr_parameters = {
        :"spellcheck.dictionary" => "identifier"
      }
      solr_name = solr_name("desc_metadata__id", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('based_near') do |field|
      field.label = "Location"
      field.solr_parameters = {
        :"spellcheck.dictionary" => "based_near"
      }
      solr_name = solr_name("desc_metadata__based_near", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('tag') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "tag"
      }
      solr_name = solr_name("desc_metadata__tag", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('depositor') do |field|
      solr_name = solr_name("desc_metadata__depositor", :stored_searchable)
      field.solr_local_parameters = {
        qf: solr_name,
        pf: solr_name
      }
    end

    config.add_search_field('rights') do |field|
      solr_name = solr_name("desc_metadata__rights", :stored_searchable)
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
