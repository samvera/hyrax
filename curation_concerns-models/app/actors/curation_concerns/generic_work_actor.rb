
module CurationConcerns
  class GenericWorkActor < CurationConcerns::BaseActor
    include CurationConcerns::ManagesEmbargoesActor

    def create
      # set the @files ivar then remove the files attribute so it isn't set by default.
      files && attributes.delete(:files)
      assign_pid && interpret_visibility && super && attach_files && create_linked_resources && assign_representative && copy_visibility
    end

    def update
      add_to_collections(attributes.delete(:collection_ids)) &&
          interpret_visibility && super && attach_files && create_linked_resources && copy_visibility
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
      #remove from old collections
      (curation_concern.collection_ids - new_collection_ids).each do |old_id|
        Collection.find(old_id).members.delete(curation_concern)
      end

      #add to new
      new_collection_ids.each do |coll_id|
        collection = Collection.find(coll_id)
        collection.members << curation_concern
        collection.save
      end
      true
    end

    def linked_resource_urls
      @linked_resource_urls ||= Array(attributes[:linked_resource_urls]).flatten.compact
    end

    def create_linked_resources
      linked_resource_urls.all? do |link_resource_url|
        create_linked_resource(link_resource_url)
      end
    end

    def create_linked_resource(link_resource_url)
      return true unless link_resource_url.present?
      resource = CurationConcerns::LinkedResource.new.tap do |link|
        link.url = link_resource_url
        link.batch = curation_concern
        link.label = curation_concern.human_readable_type
      end
      Sufia::GenericFile::Actor.new(resource, user).create_metadata(curation_concern.id, curation_concern.id)
      resource.save
    end

    def assign_representative
      curation_concern.representative = curation_concern.generic_file_ids.first
      curation_concern.save
    end

    private

    def attach_file(file)
      generic_file = GenericFile.new
      actor = Sufia::GenericFile::Actor.new(generic_file, user)
      actor.create_content(file, file.original_filename, file.content_type)
      actor.create_metadata(curation_concern.id, curation_concern.id)
      generic_file.generic_work = curation_concern
      generic_file.visibility = visibility

      stat = CurationConcerns::CurationConcern.attach_file(generic_file, user, file)
      curation_concern.generic_files += [generic_file]
    end

    def valid_file?(file_path)
      return file_path.present? && File.exists?(file_path) && !File.zero?(file_path)
    end

    # The path of the fedora node where we store the file data
    def file_path
      'content'
    end
  end
end
