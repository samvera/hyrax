# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
class DashboardController < ApplicationController
  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  include ActionView::Helpers::DateHelper

  before_filter :enforce_access_controls
  before_filter :enforce_viewing_context_for_show_requests, :only=>:show
  # This applies appropriate access controls to all solr queries (the internal method of this is overidden bellow to only include edit files)
  DashboardController.solr_search_params_logic << :add_access_controls_to_solr_params
  # This filters out objects that you want to exclude from search results, like FileAssets
  DashboardController.solr_search_params_logic << :exclude_unwanted_models

  before_filter :authenticate_user!
  before_filter :enforce_access_controls

  def index
    extra_head_content << view_context.auto_discovery_link_tag(:rss, url_for(params.merge(:format => 'rss')), :title => "RSS for results")
    extra_head_content << view_context.auto_discovery_link_tag(:atom, url_for(params.merge(:format => 'atom')), :title => "Atom for results")
    (@response, @document_list) = get_search_results
    @user = current_user
    @events = @user.events(100)
    @last_event_timestamp = @user.events.first[:timestamp].to_i || 0 rescue 0
    @filters = params[:f] || []

    respond_to do |format|
      format.html { save_current_search_params }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
    end
  end

  def activity
    # reverse events since we're prepending rows. without reverse, old events wind up first
    events = current_user.events.reverse
    # filter events to include only those that have occurred since params[:since]
    events.select! { |event| event[:timestamp].to_i > params[:since].to_i } if params[:since]
    # return the event, a formatted date string, and a numerical timestamp
    render :json => events.map { |event| [event[:action], "#{time_ago_in_words(Time.at(event[:timestamp].to_i))} ago", event[:timestamp].to_i] }
  rescue
    render :json => [] 
  end


  configure_blacklight do |config|
    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = {
      :qt => "search",
      :rows => 10
    }

    # solr field configuration for search results/index views
    config.index.show_link = "generic_file__title_display"
    config.index.record_display_type = "id"

    # solr field configuration for document/show views
    config.show.html_title = "generic_file__title_display"
    config.show.heading = "generic_file__title_display"
    config.show.display_type = "has_model_s"

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    config.add_facet_field "generic_file__resource_type_facet", :label => "Resource Type", :limit => 5
    #config.add_facet_field "generic_file__contributor_facet", :label => "Contributor", :limit => 5
    config.add_facet_field "generic_file__creator_facet", :label => "Creator", :limit => 5
    config.add_facet_field "generic_file__tag_facet", :label => "Keyword", :limit => 5
    config.add_facet_field "generic_file__subject_facet", :label => "Subject", :limit => 5
    config.add_facet_field "generic_file__language_facet", :label => "Language", :limit => 5
    config.add_facet_field "generic_file__based_near_facet", :label => "Location", :limit => 5
    config.add_facet_field "generic_file__publisher_facet", :label => "Publisher", :limit => 5
    config.add_facet_field "file_format_facet", :label => "File Format", :limit => 5

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params[:"facet.field"] = config.facet_fields.keys

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    config.add_index_field "generic_file__title_display", :label => "Title"
    config.add_index_field "generic_file__description_display", :label => "Description"
    config.add_index_field "generic_file__tag_display", :label => "Keyword"
    config.add_index_field "generic_file__subject_display", :label => "Subject"
    config.add_index_field "generic_file__creator_display", :label => "Creator"
    config.add_index_field "generic_file__contributor_display", :label => "Contributor"
    config.add_index_field "generic_file__publisher_display", :label => "Publisher"
    config.add_index_field "generic_file__based_near_display", :label => "Location"
    config.add_index_field "generic_file__language_display", :label => "Language"
    config.add_index_field "generic_file__date_uploaded_display", :label => "Date Uploaded"
    config.add_index_field "generic_file__date_modified_display", :label => "Date Modified"
    config.add_index_field "generic_file__date_created_display", :label => "Date Created"
    config.add_index_field "generic_file__rights_display", :label => "Rights"
    config.add_index_field "generic_file__resource_type_display", :label => "Resource Type"
    config.add_index_field "generic_file__format_display", :label => "Format"
    config.add_index_field "generic_file__identifier_display", :label => "Identifier"

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display
    config.add_show_field "generic_file__title_display", :label => "Title"
    config.add_show_field "generic_file__description_display", :label => "Description"
    config.add_show_field "generic_file__tag_display", :label => "Keyword"
    config.add_show_field "generic_file__subject_display", :label => "Subject"
    config.add_show_field "generic_file__creator_display", :label => "Creator"
    config.add_show_field "generic_file__contributor_display", :label => "Contributor"
    config.add_show_field "generic_file__publisher_display", :label => "Publisher"
    config.add_show_field "generic_file__based_near_display", :label => "Location"
    config.add_show_field "generic_file__language_display", :label => "Language"
    config.add_show_field "generic_file__date_uploaded_display", :label => "Date Uploaded"
    config.add_show_field "generic_file__date_modified_display", :label => "Date Modified"
    config.add_show_field "generic_file__date_created_display", :label => "Date Created"
    config.add_show_field "generic_file__rights_display", :label => "Rights"
    config.add_show_field "generic_file__resource_type_display", :label => "Resource Type"
    config.add_show_field "generic_file__format_display", :label => "File Format"
    config.add_show_field "generic_file__identifier_display", :label => "Identifier"

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
    config.add_search_field 'all_fields', :label => 'All Fields'

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
      field.solr_local_parameters = {
        :qf => "$contributor_qf",
        :pf => "$contributor_pf"
      }
    end

    config.add_search_field('creator') do |field|
      field.solr_parameters = { :"spellcheck.dictionary" => "creator" }
      field.solr_local_parameters = {
        :qf => "$creator_qf",
        :pf => "$creator_pf"
      }
    end

    config.add_search_field('title') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "title"
      },
      field.solr_local_parameters = {
        :qf => "$title_qf",
        :pf => "$title_pf"
      }
    end

    config.add_search_field('description') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "description"
      }
      field.solr_local_parameters = {
        :qf => "$description_qf",
        :pf => "$description_pf"
      }
    end

    config.add_search_field('publisher') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "publisher"
      }
      field.solr_local_parameters = {
        :qf => "$publisher_qf",
        :pf => "$publisher_pf"
      }
    end

    config.add_search_field('date_created') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "date_created"
      }
      field.solr_local_parameters = {
        :qf => "$date_created_qf",
        :pf => "$date_created_pf"
      }
    end

    config.add_search_field('subject') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "subject"
      }
      field.solr_local_parameters = {
        :qf => "$subject_qf",
        :pf => "$subject_pf"
      }
    end

    config.add_search_field('language') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "language"
      }
      field.solr_local_parameters = {
        :qf => "$language_qf",
        :pf => "$language_pf"
      }
    end

    config.add_search_field('resource_type') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "resource_type"
      }
      field.solr_local_parameters = {
        :qf => "$resource_type_qf",
        :pf => "$resource_type_pf"
      }
    end

    config.add_search_field('format') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "format"
      }
      field.solr_local_parameters = {
        :qf => "$format_qf",
        :pf => "$format_pf"
      }
    end

    config.add_search_field('identifier') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "identifier"
      }
      field.solr_local_parameters = {
        :qf => "$identifier_qf",
        :pf => "$identifier_pf"
      }
    end

    config.add_search_field('based_near') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "based_near"
      }
      field.solr_local_parameters = {
        :qf => "$based_near_qf",
        :pf => "$based_near_pf"
      }
    end

    config.add_search_field('tag') do |field|
      field.solr_parameters = {
        :"spellcheck.dictionary" => "tag"
      }
      field.solr_local_parameters = {
        :qf => "$tag_qf",
        :pf => "$tag_pf"
      }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value
    config.add_sort_field 'score desc, generic_file__date_uploaded_sort desc', :label => 'relevance'
    config.add_sort_field 'generic_file__date_uploaded_sort desc', :label => 'date uploaded'
    config.add_sort_field 'generic_file__date_modified_sort desc', :label => 'date modified'

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5
  end

  protected
  # show only files with edit permissions in lib/hydra/access_controls_enforcement.rb apply_gated_discovery
  def discovery_permissions
    ["edit"]
  end
end
