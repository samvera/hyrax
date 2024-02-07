# frozen_string_literal: true
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
        apply_creation_data_to_curation_concern(env)
        apply_save_data_to_curation_concern(env)

        save(env, use_valkyrie: Hyrax.config.use_valkyrie?) &&
          next_actor.create(env) &&
          run_callbacks(:after_create_concern, env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        apply_update_data_to_curation_concern(env)
        apply_save_data_to_curation_concern(env)
        next_actor.update(env) && save(env) && run_callbacks(:after_update_metadata, env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if destroy was successful
      def destroy(env)
        env.curation_concern.in_collection_ids.each do |id|
          destination_collection = ::Collection.find(id)
          destination_collection.members.delete(env.curation_concern)
          destination_collection.update_index
        end
        env.curation_concern.destroy
      end

      private

      def run_callbacks(hook, env)
        Hyrax.config.callback.run(hook, env.curation_concern, env.user, warn: false)
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

      def save(env, use_valkyrie: false)
        # NOTE: You must call env.curation_concern.save before you attempt to coerce the curation
        # concern into a valkyrie resource.
        is_valid = env.curation_concern.save
        return is_valid unless use_valkyrie

        # don't run validations again on the converted object if they've already passed
        resource = valkyrie_save(resource: env.curation_concern.valkyrie_resource, is_valid: is_valid)

        # we need to manually set the id and reload, because the actor stack requires
        # `env.curation_concern` to be the exact same instance throughout.
        # casting back to ActiveFedora doesn't satisfy this.
        env.curation_concern.id = resource.alternate_ids.first.id unless env.curation_concern.id
        env.curation_concern.reload
      rescue Wings::Valkyrie::Persister::FailedSaveError => _err
        # for now, just hit the validation error again
        # later we should capture the _err.obj and pass it back
        # through the environment
        is_valid
      end

      def apply_save_data_to_curation_concern(env)
        env.curation_concern.attributes = clean_attributes(env.attributes)
        env.curation_concern.date_modified = TimeService.time_in_utc
      end

      # Cast any singular values from the form to multiple values for persistence
      # also remove any blank assertions
      def clean_attributes(attributes)
        attributes[:license] = Array(attributes[:license]) if attributes.key? :license
        attributes[:rights_statement] = Array(attributes[:rights_statement]) if attributes.key? :rights_statement
        remove_blank_attributes!(attributes).except('file_set')
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

      def valkyrie_save(resource:, is_valid:)
        permissions = resource.permission_manager.acl.permissions
        resource    = Hyrax.persister.save(resource: resource, perform_af_validation: !is_valid)

        resource.permission_manager.acl.permissions = permissions
        resource.permission_manager.acl.save
        resource
      end
    end
  end
end
