module Hyrax
  class TrophyPresenter
    include ModelProxy
    def initialize(solr_document)
      @solr_document = solr_document
    end

    attr_reader :solr_document

    delegate :to_s, :thumbnail_path, to: :solr_document

    # @param user [User] the user to find the TrophyPresentes for.
    # @return [Array<TrophyPresenter>] a list of all the trophy presenters for the user
    def self.find_by_user(user)
      work_ids = user.trophies.pluck(:work_id)
      results = work_ids.collect { |id| find_work(id) }.compact
      results.map { |result| TrophyPresenter.new(document_model.new(result)) }
    end

    def self.find_work(id)
      Hyrax::Queries.find_work(id: Valkyrie::ID.new(id))
    rescue Valkyrie::Persistence::ObjectNotFoundError, Hyrax::ObjectNotFoundError
      nil
    end
    private_class_method :find_work

    def self.document_model
      CatalogController.blacklight_config.document_model
    end
    private_class_method :document_model
  end
end
