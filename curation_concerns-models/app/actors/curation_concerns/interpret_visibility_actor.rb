module CurationConcerns
  class InterpretVisibilityActor < AbstractActor
    class Intention
      def initialize(attributes)
        @attributes = attributes
      end

      # returns a copy of attributes with the necessary params removed
      # If the lease or embargo is valid, or if they selected something besides lease
      # or embargo, remove all the params.
      def sanitize_params
        if valid_lease?
          @attributes.except(:visibility,
                             :embargo_release_date,
                             :visibility_during_embargo,
                             :visibility_after_embargo)
        elsif valid_embargo?
          @attributes.except(:visibility,
                             :lease_expiration_date,
                             :visibility_during_lease,
                             :visibility_after_lease)
        elsif !wants_lease? && !wants_embargo?
          @attributes.except(:lease_expiration_date,
                             :visibility_during_lease,
                             :visibility_after_lease,
                             :embargo_release_date,
                             :visibility_during_embargo,
                             :visibility_after_embargo)
        else
          @attributes
        end
      end

      def wants_lease?
        visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE
      end

      def wants_embargo?
        visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
      end

      def valid_lease?
        wants_lease? && @attributes[:lease_expiration_date].present?
      end

      def valid_embargo?
        wants_embargo? && @attributes[:embargo_release_date].present?
      end

      def lease_params
        [:lease_expiration_date,
         :visibility_during_lease,
         :visibility_after_lease].map { |key| @attributes[key] }
      end

      def embargo_params
        [:embargo_release_date,
         :visibility_during_embargo,
         :visibility_after_embargo].map { |key| @attributes[key] }
      end

      private

        def visibility
          @attributes[:visibility]
        end
    end

    def create(attributes)
      @intention = Intention.new(attributes)
      attributes = @intention.sanitize_params
      validate && apply_visibility(attributes) && next_actor.create(attributes)
    end

    def update(attributes)
      @intention = Intention.new(attributes)
      attributes = @intention.sanitize_params
      validate && apply_visibility(attributes) && next_actor.update(attributes)
    end

    private

      def validate
        validate_lease && validate_embargo
      end

      def apply_visibility(attributes)
        result = apply_lease && apply_embargo
        if attributes[:visibility]
          curation_concern.visibility = attributes[:visibility]
        end
        result
      end

      def validate_lease
        return true unless @intention.wants_lease? && !@intention.valid_lease?
        curation_concern.errors.add(:visibility, 'When setting visibility to "lease" you must also specify lease expiration date.')
        false
      end

      def validate_embargo
        return true unless @intention.wants_embargo? && !@intention.valid_embargo?
        curation_concern.errors.add(:visibility, 'When setting visibility to "embargo" you must also specify embargo release date.')
        false
      end

      # If they want a lease, we can assume it's valid
      def apply_lease
        return true unless @intention.wants_lease?
        curation_concern.apply_lease(*@intention.lease_params)
        return unless curation_concern.lease
        curation_concern.lease.save # see https://github.com/projecthydra/hydra-head/issues/226
      end

      # If they want an embargo, we can assume it's valid
      def apply_embargo
        return true unless @intention.wants_embargo?
        curation_concern.apply_embargo(*@intention.embargo_params)
        return unless curation_concern.embargo
        curation_concern.embargo.save # see https://github.com/projecthydra/hydra-head/issues/226
      end
  end
end
