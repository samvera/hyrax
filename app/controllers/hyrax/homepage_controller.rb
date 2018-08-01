class Hyrax::HomepageController < ApplicationController
  # Adds Hydra behaviors into the application controller
  include Blacklight::SearchContext
  include Blacklight::SearchHelper
  include Blacklight::AccessControls::Catalog

  # The search builder for finding recent documents
  # Override of Blacklight::RequestBuilders
  def search_builder_class
    Hyrax::HomepageSearchBuilder
  end

  class_attribute :presenter_class
  self.presenter_class = Hyrax::HomepagePresenter
  layout 'homepage'
  helper Hyrax::ContentBlockHelper

  def index
    @presenter = presenter_class.new(current_ability, collections)
    @featured_researcher = ContentBlock.for(:researcher)
    @marketing_text = ContentBlock.for(:marketing)
    @featured_work_list = FeaturedWorkList.new
    @announcement_text = ContentBlock.for(:announcement)
    recent
  end

  private

    # Return 5 collections
    def collections(rows: 5)
      builder = Hyrax::CollectionSearchBuilder.new(self)
                                              .rows(rows)
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
      "#{Solrizer.solr_name('date_uploaded', :stored_sortable, type: :date)} desc"
    end
end
