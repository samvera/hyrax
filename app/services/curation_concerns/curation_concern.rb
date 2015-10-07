module CurationConcerns
  module CurationConcern
    def self.actor(curation_concern, *args)
      actor_identifier = curation_concern.class.to_s.split('::').last
      klass = "CurationConcerns::#{actor_identifier}Actor".constantize
      klass.new(curation_concern, *args)
    end
  end
end
