module CurationConcerns
  class FormPresenter
    include ModelProxy
    attr_accessor :curation_concern, :current_ability

    # @param [ActiveFedora::Base] curation_concern
    # @param [Ability] current_ability
    def initialize(curation_concern, current_ability)
      @curation_concern = curation_concern
      @current_ability = current_ability
    end

    # @return [Hash] All generic files in the collection, file.to_s is the key, file.id is the value
    def files_hash
      Hash[file_presenters.map { |file| [file.to_s, file.id] }]
    end

    # @return [Array<GenericFilePresenter>] presenters for the generic files in order of the ids
    def file_presenters
      @generic_files ||= begin
        load_generic_file_presenters(curation_concern.member_ids)
      end
    end

    private

      # @param [Array] ids the list of ids to load
      # @return [Array<GenericFilePresenter>] presenters for the generic files in order of the ids
      def load_generic_file_presenters(ids)
        return [] if ids.blank?
        docs = ActiveFedora::SolrService.query("{!terms f=id}#{ids.join(',')}").map { |res| SolrDocument.new(res) }
        ids.map { |id| GenericFilePresenter.new(docs.find { |doc| doc.id == id }, current_ability) }
      end
  end
end
