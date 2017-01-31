module Hyrax
  module Actors
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
            sanitize_lease_params
          elsif valid_embargo?
            sanitize_embargo_params
          elsif !wants_lease? && !wants_embargo?
            sanitize_unrestricted_params
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

          def sanitize_unrestricted_params
            @attributes.except(:lease_expiration_date,
                               :visibility_during_lease,
                               :visibility_after_lease,
                               :embargo_release_date,
                               :visibility_during_embargo,
                               :visibility_after_embargo)
          end

          def sanitize_embargo_params
            @attributes.except(:visibility,
                               :lease_expiration_date,
                               :visibility_during_lease,
                               :visibility_after_lease)
          end

          def sanitize_lease_params
            @attributes.except(:visibility,
                               :embargo_release_date,
                               :visibility_during_embargo,
                               :visibility_after_embargo)
          end

          def visibility
            @attributes[:visibility]
          end
      end

      def create(attributes)
        @intention = Intention.new(attributes)
        attributes = @intention.sanitize_params
        validate(attributes) && apply_visibility(attributes) && next_actor.create(attributes)
      end

      def update(attributes)
        @intention = Intention.new(attributes)
        attributes = @intention.sanitize_params
        validate(attributes) && apply_visibility(attributes) && next_actor.update(attributes)
      end

      private

        # Validate against selected AdminSet's PermissionTemplate (if any)
        def validate(attributes)
          # If AdminSet was selected, look for its PermissionTemplate
          template = PermissionTemplate.find_by!(admin_set_id: attributes[:admin_set_id]) if attributes[:admin_set_id].present?

          validate_lease(template) && validate_release_type(template) && validate_visibility(attributes, template) && validate_embargo(attributes, template)
        end

        def apply_visibility(attributes)
          result = apply_lease && apply_embargo
          if attributes[:visibility]
            curation_concern.visibility = attributes[:visibility]
          end
          result
        end

        # Validate that a lease is allowed by AdminSet's PermissionTemplate
        def validate_lease(template)
          return true unless @intention.wants_lease?

          # Leases are only allowable if a template doesn't require a release period or have any specific visibility requirement
          # (Note: permission template release/visibility options do not support leases)
          unless template.present? && (template.release_period.present? || template.visibility.present?)
            return true if @intention.valid_lease?
            curation_concern.errors.add(:visibility, 'When setting visibility to "lease" you must also specify lease expiration date.')
            return false
          end

          curation_concern.errors.add(:visibility, 'Lease option is not allowed by permission template for selected AdminSet.')
          false
        end

        # Validate the selected release settings against template, checking for when embargoes/leases are not allowed
        def validate_release_type(template)
          # It's valid as long as embargo is not specified when a template requires no release delays
          return true unless @intention.wants_embargo? && template.present? && template.release_no_delay?

          curation_concern.errors.add(:visibility, 'Visibility specified does not match permission template "no release delay" requirement for selected AdminSet.')
          false
        end

        # Validate visibility complies with AdminSet template requirements
        def validate_visibility(attributes, template)
          # NOTE: For embargo/lease, attributes[:visibility] will be nil (see sanitize_params), so visibility will be validated as part of embargo/lease
          return true unless attributes[:visibility].present?

          # Validate against template's visibility requirements
          return true if validate_template_visibility(attributes[:visibility], template)

          curation_concern.errors.add(:visibility, 'Visibility specified does not match permission template visibility requirement for selected AdminSet.')
          false
        end

        # When specified, validate embargo is a future date that complies with AdminSet template requirements (if any)
        def validate_embargo(attributes, template)
          return true unless @intention.wants_embargo?

          embargo_release_date = parse_date(attributes[:embargo_release_date])

          # When embargo required, date must be in future AND matches any template requirements
          return true if valid_future_date?(embargo_release_date) &&
                         valid_template_embargo_date?(embargo_release_date, template) &&
                         valid_template_visibility_after_embargo?(attributes, template)

          curation_concern.errors.add(:visibility, 'When setting visibility to "embargo" you must also specify embargo release date.') unless embargo_release_date.present?
          false
        end

        # Validate an date attribute is in the future
        def valid_future_date?(date, attribute_name: :embargo_release_date)
          return true if date.present? && date.future?

          curation_concern.errors.add(attribute_name, "Must be a future date.")
          false
        end

        # Validate an embargo date against permission template restrictions
        def valid_template_embargo_date?(date, template)
          return true unless template.present?

          # Validate against template's release_date requirements
          return true if template.valid_release_date?(date)

          curation_concern.errors.add(:embargo_release_date, "Release date specified does not match permission template release requirements for selected AdminSet.")
          false
        end

        # Validate the post-embargo visibility against permission template requirements (if any)
        def valid_template_visibility_after_embargo?(attributes, template)
          # Validate against template's visibility requirements
          return true if validate_template_visibility(attributes[:visibility_after_embargo], template)

          curation_concern.errors.add(:visibility_after_embargo, "Visibility after embargo does not match permission template visibility requirements for selected AdminSet.")
          false
        end

        # Validate that a given visibility value satisfies template requirements
        def validate_template_visibility(visibility, template)
          return true unless template.present?

          template.valid_visibility?(visibility)
        end

        # Parse date from string. Returns nil if date_string is not a valid date
        def parse_date(date_string)
          datetime = Time.zone.parse(date_string) if date_string.present?
          return datetime.to_date unless datetime.nil?
          nil
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
end
