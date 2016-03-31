module CurationConcerns
  class RootActor
    attr_reader :curation_concern, :user, :attributes, :cloud_resources
    def initialize(curation_concern, user, attributes, _more_actors)
      @curation_concern = curation_concern
      @user = user
      @attributes = attributes
    end

    def create
      true
    end

    def update
      true
    end
  end
end
