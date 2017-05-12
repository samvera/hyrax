module Hyrax::HomepageControllerBehavior
  extend ActiveSupport::Concern

  included do
    # Adds Hydra behaviors into the application controller
    include Blacklight::SearchContext
    include Blacklight::SearchHelper
    include Blacklight::AccessControls::Catalog

    def search_builder_class
      Hyrax::HomepageSearchBuilder
    end

    class_attribute :presenter_class
    self.presenter_class = Hyrax::HomepagePresenter
    layout 'homepage'
    helper Hyrax::ContentBlockHelper
  end

  def index
    @presenter = presenter_class.new(current_ability)
    @featured_researcher = ContentBlock.for(:researcher)
    @marketing_text = ContentBlock.for(:marketing)
    @featured_work_list = FeaturedWorkList.new
    @announcement_text = ContentBlock.for(:announcement)
    @admin_sets = fetch_admin_sets
    recent
  end

  private

    def fetch_admin_sets
      return [] unless Flipflop.assign_admin_set?
      builder = Hyrax::AdminSetSearchBuilder.new(self, current_ability)
                                            .rows(5)
      response = repository.search(builder)
      response.documents
    rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
      []
    end

    def recent
      # grab any recent documents
      (_, @recent_documents) = search_results(q: '', sort: sort_field, rows: 4)
    rescue Blacklight::Exceptions::ECONNREFUSED, Blacklight::Exceptions::InvalidRequest
      @recent_documents = []
    end

    def sort_field
      "#{Solrizer.solr_name('system_create', :stored_sortable, type: :date)} desc"
    end
end
