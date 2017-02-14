module Hyrax
  module Actors
    class RootActor
      attr_reader :curation_concern, :user, :cloud_resources
      def initialize(curation_concern, user, _more_actors, ability: nil)
        @curation_concern = curation_concern
        @user = user
        @ability = ability
      end

      def create(_)
        true
      end

      def update(_)
        true
      end
    end
  end
end
