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
        PresenterFactory.build_presenters(curation_concern.member_ids, GenericFilePresenter, current_ability)
      end
    end
  end
end
