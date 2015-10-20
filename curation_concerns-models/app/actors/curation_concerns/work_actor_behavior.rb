module CurationConcerns::WorkActorBehavior
  include CurationConcerns::ManagesEmbargoesActor
  attr_accessor :raw_attributes

  def create
    # set the @files ivar then remove the files attribute so it isn't set by default.
    files && attributes.delete(:files)
    self.raw_attributes = attributes.dup
    # Files must be attached before saving in order to persist their relationship to the work
    assign_pid && interpret_visibility && attach_files && super && assign_representative
  end

  def update
    add_to_collections(attributes.delete(:collection_ids)) &&
      interpret_visibility && super && attach_files
  end

  delegate :visibility_changed?, to: :curation_concern

  protected

    # Is this here to ensure that the curation_concern has a pid set before any of the other methods are executed?
    def assign_pid
      curation_concern.send(:assign_id)
    end

    def files
      return @files if defined?(@files)
      @files = [attributes[:files]].flatten.compact
    end

    def attach_files
      files.all? do |file|
        attach_file(file)
      end
    end

    # The default behavior of active_fedora's aggregates association,
    # when assigning the id accessor (e.g. collection_ids = ['foo:1']) is to add
    # to new collections, but not remove from old collections.
    # This method ensures it's removed from the old collections.
    def add_to_collections(new_collection_ids)
      return true unless new_collection_ids
      # remove from old collections
      # TODO: Implement in_collection_ids https://github.com/projecthydra-labs/hydra-pcdm/issues/157
      (curation_concern.in_collections.map(&:id) - new_collection_ids).each do |old_id|
        collection = Collection.find(old_id)
        collection.members.delete(curation_concern)
        collection.save
      end

      # add to new
      new_collection_ids.each do |coll_id|
        collection = Collection.find(coll_id)
        collection.members << curation_concern
        collection.save
      end
      true
    end

    def assign_representative
      @file_sets ||= []
      unless curation_concern.representative_id
        curation_concern.representative = @file_sets.first unless @file_sets.empty?
      end
      curation_concern.save
    end

  private

    def attach_file(file)
      file_set = ::FileSet.new
      file_set_actor = CurationConcerns::FileSetActor.new(file_set, user)
      file_set_actor.create_metadata(curation_concern.id, curation_concern, visibility_attributes)
      file_set_actor.create_content(file)
      @file_sets ||= []
      @file_sets << file_set # This is so that other methods like assign_representative can access the file_sets without reloading them from fedora
    end

    # The attributes used for visibility - used to send as initial params to
    # created FileSets.
    def visibility_attributes
      raw_attributes.slice(:visibility, :visibility_during_lease, :visibility_after_lease, :lease_expiration_date, :embargo_release_date, :visibility_during_embargo, :visibility_after_embargo)
    end

    def valid_file?(file_path)
      file_path.present? && File.exist?(file_path) && !File.zero?(file_path)
    end

    # The path of the fedora node where we store the file data
    def file_path
      'content'
    end
end
