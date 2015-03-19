module Sufia::HomepageController
  extend ActiveSupport::Concern

  included do
    # Adds Hydra behaviors into the application controller
    include Hydra::Controller::ControllerBehavior
    include Blacklight::Catalog::SearchContext
    include Sufia::Controller
    include Blacklight::SearchHelper
    include Hydra::Controller::SearchBuilder

    self.search_params_logic += [:show_only_generic_files, :add_access_controls_to_solr_params]
    layout 'homepage'
  end

  def index
    @featured_researcher = ContentBlock.featured_researcher
    @featured_researcher ||= ContentBlock.create(name: ContentBlock::RESEARCHER)
    @marketing_text = ContentBlock.find_or_create_by(name: ContentBlock::MARKETING)
    @featured_work_list = FeaturedWorkList.new
    recent
  end

  protected

  def recent
    # grab any recent documents
    (_, @recent_documents) = search_results({q: '', sort:sort_field, rows: 4}, search_params_logic)
  end

  def sort_field
    "#{Solrizer.solr_name('system_create', :stored_sortable, type: :date)} desc"
  end

end
