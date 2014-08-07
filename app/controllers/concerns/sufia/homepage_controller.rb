module Sufia::HomepageController
  extend ActiveSupport::Concern

  included do
    # Adds Hydra behaviors into the application controller
    include Hydra::Controller::ControllerBehavior
    include Blacklight::Catalog::SearchContext
    include Sufia::Controller
    include Blacklight::SolrHelper

    self.solr_search_params_logic += [:only_generic_files, :add_access_controls_to_solr_params]
    layout 'homepage'
  end

  def index
    @featured_researcher = ContentBlock.find_or_create_by(name: 'featured_researcher')
    @marketing_text = ContentBlock.find_or_create_by(name: 'marketing_text')
    @featured_work_list = FeaturedWorkList.new
    recent
  end

  protected

  def recent
    # grab any recent documents
    (_, @recent_documents) = get_search_results(q: '', sort:sort_field, rows: 4)
  end

  def sort_field
    "#{Solrizer.solr_name('system_create', :stored_sortable, type: :date)} desc"
  end

  # Limits search results just to GenericFiles
  # @param solr_parameters the current solr parameters
  # @param user_parameters the current user-subitted parameters
  def only_generic_files(solr_parameters, user_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "#{Solrizer.solr_name("has_model", :symbol)}:\"info:fedora/afmodel:GenericFile\""
  end

end
