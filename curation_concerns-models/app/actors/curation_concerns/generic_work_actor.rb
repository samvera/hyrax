
module CurationConcerns
  class GenericWorkActor < CurationConcerns::BaseActor
    include CurationConcerns::ManagesEmbargoesActor

    def create
      assign_id && interpret_visibility && super && attach_files && assign_representative && copy_visibility
    end

    def update
      ##add_to_collections(attributes.delete(:collection_ids)) && 
      interpret_visibility  && super && attach_files && copy_visibility
    end

    delegate :visibility_changed?, to: :curation_concern

    protected

    # Is this here to ensure that the curation_concern has an id set before any of the other methods are executed?
    def assign_id
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

    # The default behavior of active_fedora's has_and_belongs_to_many association,
    # when assigning the id accessor (e.g. collection_ids = ['foo:1']) is to add
    # to new collections, but not remove from old collections.
    # This method ensures it's removed from the old collections.
    # def add_to_collections(new_collection_ids)
    #   return true unless new_collection_ids
    #   #remove from old collections
    #   (curation_concern.collection_ids - new_collection_ids).each do |old_id|
    #     Collection.find(old_id).members.delete(curation_concern)
    #   end

    #   #add to new
    #   curation_concern.collection_ids = new_collection_ids
    #   true
    # end

    # def linked_resource_urls
    #   @linked_resource_urls ||= Array(attributes[:linked_resource_urls]).flatten.compact
    # end

    # def create_linked_resources
    #   linked_resource_urls.all? do |link_resource_url|
    #     create_linked_resource(link_resource_url)
    #   end
    # end

    # def create_linked_resource(link_resource_url)
    #   return true unless link_resource_url.present?
    #   resource = CurationConcerns::LinkedResource.new.tap do |link|
    #     link.url = link_resource_url
    #     link.batch = curation_concern
    #     link.label = curation_concern.human_readable_type
    #   end
    #   Sufia::GenericFile::Actor.new(resource, user).create_metadata(curation_concern.id)
    #   resource.save
    # end

    def assign_representative
      curation_concern.representative = curation_concern.generic_file_ids.first
      curation_concern.save
    end

    private
    def attach_file(file)
      generic_file = CurationConcerns::GenericFile.new
      generic_file.file = file
      generic_file.batch = curation_concern
      Sufia::GenericFile::Actor.new(generic_file, user).create_metadata(curation_concern.id)
      generic_file.embargo_release_date = curation_concern.embargo_release_date
      generic_file.visibility = visibility
      CurationConcerns::CurationConcern.attach_file(generic_file, user, file)
    end


    def valid_file?(file_path)
      return file_path.present? && File.exists?(file_path) && !File.zero?(file_path)
    end
  end
end
