module Hyrax
  module Actors
    class ActorStack
      attr_reader :curation_concern, :user, :first_actor_class, :more_actors
      def initialize(curation_concern, user_or_ability, more_actors)
        @curation_concern = curation_concern
        self.user = user_or_ability
        @more_actors = more_actors
        @first_actor_class = @more_actors.shift || RootActor
      end

      def inner_stack
        Actors::ActorStack.new(curation_concern, ability, more_actors)
      end

      def actor
        ## Change this to pass in the ability instead of user for next version.
        first_actor_class.new(curation_concern, user, inner_stack, ability: ability)
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

      def ability
        @ability ||= ::Ability.new(user)
      end

      private

        def user=(user_or_ability)
          if user_or_ability.respond_to?(:current_user)
            @user = user_or_ability.current_user
            @ability = user_or_ability
          else
            Deprecation.warn(self, "Passing a user as an argument to Hyrax::Actors::ActorStack is deprecated, pass an Ability instead")
            @user = user_or_ability
            @ability = ::Ability.new(user)
          end
        end

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
