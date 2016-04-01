module CurationConcerns
  class RootActor
    attr_reader :curation_concern, :user, :cloud_resources
    def initialize(curation_concern, user, _more_actors)
      @curation_concern = curation_concern
      @user = user
    end

    def create(_)
      true
    end

    def update(_)
      true
    end
  end
end
