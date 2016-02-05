module Sufia::HomepageControllerBehavior
  extend ActiveSupport::Concern

  included do
    # Adds Hydra behaviors into the application controller
    include Hydra::Controller::ControllerBehavior
    include Blacklight::SearchContext
    include Sufia::Controller
    include Blacklight::SearchHelper
    include Blacklight::AccessControls::Catalog

    def search_builder_class
      Sufia::HomepageSearchBuilder
    end

    layout 'homepage'
  end

  def index
    @featured_researcher = ContentBlock.featured_researcher
    @featured_researcher ||= ContentBlock.create(name: ContentBlock::RESEARCHER)
    @marketing_text = ContentBlock.find_or_create_by(name: ContentBlock::MARKETING)
    @featured_work_list = FeaturedWorkList.new
    @announcement_text = ContentBlock.find_or_create_by(name: ContentBlock::ANNOUNCEMENT)
    recent
  end

  protected

    def recent
      # grab any recent documents
      (_, @recent_documents) = search_results(q: '', sort: sort_field, rows: 4)
    end

    def sort_field
      "#{Solrizer.solr_name('system_create', :stored_sortable, type: :date)} desc"
    end
end
