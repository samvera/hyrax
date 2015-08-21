module CurationConcerns
  module CurationConcern
    def self.actor(curation_concern, *args)
      actor_identifier = curation_concern.class.to_s.split('::').last
      klass = "CurationConcerns::#{actor_identifier}Actor".constantize
      klass.new(curation_concern, *args)
    end

    def self.attach_file_to_generic_file(generic_file, user, file_to_attach)
      CurationConcerns::GenericFileActor.new(generic_file, user).create_content(file_to_attach)
    end
  end
end
