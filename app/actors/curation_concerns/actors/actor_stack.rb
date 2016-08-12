module CurationConcerns
  module Actors
    class ActorStack
      attr_reader :curation_concern, :user, :first_actor_class, :more_actors
      def initialize(curation_concern, user, more_actors)
        @curation_concern = curation_concern
        @user = user
        @more_actors = more_actors
        @first_actor_class = @more_actors.shift || RootActor
      end

      def inner_stack
        Actors::ActorStack.new(curation_concern, user, more_actors)
      end

      def actor
        first_actor_class.new(curation_concern, user, inner_stack)
      end

      # @param [ActionController::Parameters,Hash,NilClass] new_attributes
      def create(new_attributes)
        new_attributes ||= {}
        actor.create(new_attributes.with_indifferent_access)
      end

      # @param [ActionController::Parameters,Hash,NilClass] new_attributes
      def update(new_attributes)
        new_attributes ||= {}
        actor.update(new_attributes.with_indifferent_access)
      end

      def destroy
        curation_concern.in_collection_ids.each do |id|
          destination_collection = ::Collection.find(id)
          destination_collection.members.delete(curation_concern)
          destination_collection.update_index
        end
        curation_concern.destroy
      end
    end
  end
end
