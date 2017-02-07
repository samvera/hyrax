module CurationConcerns
  # Validates that the submitted version is the most recent version in the datastore.
  # Caveat: we are not detecting if the version is changed by a different process between
  # the time this validator is run and when the object is saved
  class OptimisticLockValidator < Actors::AbstractActor
    class_attribute :version_field
    self.version_field = 'version'

    def update(attributes)
      validate_lock(version_attribute(attributes)) && next_actor.update(attributes)
    end

    private

      # @return [Boolean] returns true if the lock is missing or
      #                   if it matches the current object version.
      def validate_lock(version)
        return true if version.blank? || version == curation_concern.etag
        curation_concern.errors.add(:base, :conflict)
        false
      end

      # Removes the version attribute
      def version_attribute(attributes)
        attributes.delete(version_field)
      end
  end
end
