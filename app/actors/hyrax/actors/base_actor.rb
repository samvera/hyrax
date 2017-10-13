module Hyrax
  module Actors
    ##
    # Defines the basic save/destroy and callback behavior, intended to run
    # near the bottom of the actor stack.
    #
    # @example Defining a base actor for a custom work type
    #   module Hyrax
    #     module Actors
    #       class MyWorkActor < Hyrax::Actors::BaseActor; end
    #     end
    #   end
    #
    # @see Hyrax::Actor::AbstractActor
    class BaseActor < AbstractActor
      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        yield env.change_set if block_given?
        return unless env.change_set.validate(env.attributes)
        env.change_set_persister.save(change_set: env.change_set) && next_actor.create(env) && run_callbacks(:after_create_concern, env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        apply_update_data_to_curation_concern(env)
        apply_save_data_to_curation_concern(env)
        next_actor.update(env) && env.change_set_persister.save(change_set: env.change_set) && run_callbacks(:after_update_metadata, env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if destroy was successful
      def destroy(env)
        env.curation_concern.in_collection_ids.each do |id|
          destination_collection = Hyrax::Queries.find_by(id: id)
          destination_collection.members.delete(env.curation_concern)
          destination_collection.update_index
        end
        env.curation_concern.destroy
      end

      private

        def run_callbacks(hook, env)
          Hyrax.config.callback.run(hook, env.curation_concern, env.user)
          true
        end

        def apply_creation_data_to_curation_concern(env)
          apply_depositor_metadata(env)
          apply_deposit_date(env)
        end

        def apply_update_data_to_curation_concern(_env)
          true
        end

        def apply_depositor_metadata(env)
          env.curation_concern.depositor = env.user.user_key
        end

        def apply_deposit_date(env)
          env.curation_concern.date_uploaded = TimeService.time_in_utc
        end

        def save(env)
          env.curation_concern.save
        end

        def apply_save_data_to_curation_concern(env)
          clean_attributes(env.attributes).each_pair do |attribute, value|
            env.curation_concern.send("#{attribute}=".to_sym, value)
          end
          env.curation_concern.date_modified = TimeService.time_in_utc
        end

        # Cast any singular values from the form to multiple values for persistence
        # also remove any blank assertions
        # TODO this method could move to the work form.
        def clean_attributes(attributes)
          attributes[:license] = Array(attributes[:license]) if attributes.key? :license
          attributes[:rights_statement] = Array(attributes[:rights_statement]) if attributes.key? :rights_statement
          remove_blank_attributes!(attributes)
        end

        # If any attributes are blank remove them
        # e.g.:
        #   self.attributes = { 'title' => ['first', 'second', ''] }
        #   remove_blank_attributes!
        #   self.attributes
        # => { 'title' => ['first', 'second'] }
        def remove_blank_attributes!(attributes)
          multivalued_form_attributes(attributes).each_with_object(attributes) do |(k, v), h|
            h[k] = v.instance_of?(Array) ? v.select(&:present?) : v
          end
        end

        # Return the hash of attributes that are multivalued and not uploaded files
        def multivalued_form_attributes(attributes)
          attributes.select { |_, v| v.respond_to?(:select) && !v.respond_to?(:read) }
        end
    end
  end
end
