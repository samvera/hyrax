# frozen_string_literal: true
module Hyrax
  module Actors
    # Validates that the submitted version is the most recent version in the datastore.
    # Caveat: we are not detecting if the version is changed by a different process between
    # the time this validator is run and when the object is saved
    class OptimisticLockValidator < Actors::AbstractActor
      class_attribute :version_field
      self.version_field = 'version'

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        validate_lock(env, version_attribute(env.attributes)) && next_actor.update(env)
      end

      private

      # @return [Boolean] returns true if the lock is missing or
      #                   if it matches the current object version.
      def validate_lock(env, version)
        return true if version.blank? || version == env.curation_concern.etag
        env.curation_concern.errors.add(:base, :conflict)
        false
      end

      # Removes the version attribute
      def version_attribute(attributes)
        attributes.delete(version_field)
      end
    end
  end
end
