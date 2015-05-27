module CurationConcerns
  class GenericFileActor < Sufia::GenericFile::Actor
    include CurationConcerns::ManagesEmbargoesActor

    attr_reader :attributes, :curation_concern

    def initialize(generic_file, user, attributes)
      super(generic_file, user)
      # we're setting attributes and curation_concern to bridge the difference
      # between Sufia::GenericFile::Actor and ManagesEmbargoesActor
      @curation_concern = generic_file
      @attributes = attributes
    end

    # we can trim this down a bit when Sufia 7.1 is released (adds update_visibility)
    def update_metadata(_, _)
      interpret_visibility # Note: this modifies the contents of attributes!
      update_visibility(attributes[:visibility]) if attributes.key?(:visibility)
      # generic_file.visibility = attributes[:visibility] if attributes.key?(:visibility)
      generic_file.attributes = attributes
      generic_file.date_modified = DateTime.now
      remove_from_feature_works if generic_file.visibility_changed? && !generic_file.public?
      save_and_record_committer do
        if Sufia.config.respond_to?(:after_update_metadata)
          Sufia.config.after_update_metadata.call(generic_file, user)
        end
      end
    end

    def create_metadata(batch_id)
      if batch_id
        generic_file.visibility = load_parent(batch_id).visibility
      end
      super
    end

    def load_parent(batch_id)
      @parent ||= GenericWork.find(batch_id)
    end
  end
end
