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
        actor.create(cast_to_indifferent_hash(new_attributes))
      end

      # @param [ActionController::Parameters,Hash,NilClass] new_attributes
      def update(new_attributes)
        actor.update(cast_to_indifferent_hash(new_attributes))
      end

      def destroy
        curation_concern.in_collection_ids.each do |id|
          destination_collection = ::Collection.find(id)
          destination_collection.members.delete(curation_concern)
          destination_collection.update_index
        end
        curation_concern.destroy
      end

      private

        # @param [ActionController::Parameters,Hash,NilClass] new_attributes
        def cast_to_indifferent_hash(new_attributes)
          new_attributes ||= {}
          if new_attributes.respond_to?(:to_unsafe_h)
            # This is the typical (not-ActionView::TestCase) code path.
            new_attributes = new_attributes.to_unsafe_h
          end
          # In Rails 5 to_unsafe_h returns a HashWithIndifferentAccess, in Rails 4 it returns Hash
          new_attributes = new_attributes.with_indifferent_access if new_attributes.instance_of? Hash
          new_attributes
        end
    end
  end
end
