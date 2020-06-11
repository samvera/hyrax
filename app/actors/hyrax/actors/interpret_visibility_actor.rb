# frozen_string_literal: true
module Hyrax
  module Actors
    class InterpretVisibilityActor < AbstractActor
      class Intention < VisibilityIntention
        def initialize(attributes)
          @attributes = attributes

          instance_vars_from_attributes
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

        private

        ##
        # This method provides compatibility between form attributes passed in
        # by the Actor, and the interface of `VisibilityIntention`. This
        # behavior might benefit from being extracted elsewhere (the Actor?
        # the form object?). Or it might be better to just expect clients to
        # only pass in one set of end_date/during/after values.
        #
        # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def instance_vars_from_attributes
          self.visibility   = @attributes[:visibility]
          self.release_date = (wants_embargo? && @attributes[:embargo_release_date].presence) ||
                              (wants_lease?   && @attributes[:lease_expiration_date].presence)
          self.after        = (wants_embargo? && @attributes[:visibility_after_embargo].presence) ||
                              (wants_lease?   && @attributes[:visibility_after_lease].presence)
          self.during       = (wants_embargo? && @attributes[:visibility_during_embargo].presence) ||
                              (wants_lease?   && @attributes[:visibility_during_lease].presence)
        end
        # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

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
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        intention = Intention.new(env.attributes)
        env.attributes = intention.sanitize_params
        validate(env, intention, env.attributes) && apply_visibility(env, intention) &&
          next_actor.create(env)
      end

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if update was successful
      def update(env)
        intention = Intention.new(env.attributes)
        env.attributes = intention.sanitize_params
        validate(env, intention, env.attributes) && apply_visibility(env, intention) &&
          next_actor.update(env)
      end

      private

      # Validate against selected AdminSet's PermissionTemplate (if any)
      def validate(env, intention, attributes)
        # If AdminSet was selected, look for its PermissionTemplate
        template = PermissionTemplate.find_by!(source_id: attributes[:admin_set_id]) if attributes[:admin_set_id].present?

        validate_lease(env, intention, template) &&
          validate_release_type(env, intention, template) &&
          validate_visibility(env, attributes, template) &&
          validate_embargo(env, intention, attributes, template)
      end

      def apply_visibility(env, intention)
        result = apply_lease(env, intention) && apply_embargo(env, intention)
        env.curation_concern.visibility = env.attributes[:visibility] if env.attributes[:visibility]
        result
      end

      # Validate that a lease is allowed by AdminSet's PermissionTemplate
      def validate_lease(env, intention, template)
        return true unless intention.wants_lease?

        # Leases are only allowable if a template doesn't require a release period or have any specific visibility requirement
        # (Note: permission template release/visibility options do not support leases)
        unless template.present? && (template.release_period.present? || template.visibility.present?)
          return true if intention.valid_lease?
          env.curation_concern.errors.add(:visibility, 'When setting visibility to "lease" you must also specify lease expiration date.')
          return false
        end

        env.curation_concern.errors.add(:visibility, 'Lease option is not allowed by permission template for selected AdminSet.')
        false
      end

      # Validate the selected release settings against template, checking for when embargoes/leases are not allowed
      def validate_release_type(env, intention, template)
        # It's valid as long as embargo is not specified when a template requires no release delays
        return true unless intention.wants_embargo? && template.present? && template.release_no_delay?

        env.curation_concern.errors.add(:visibility, 'Visibility specified does not match permission template "no release delay" requirement for selected AdminSet.')
        false
      end

      # Validate visibility complies with AdminSet template requirements
      def validate_visibility(env, attributes, template)
        # NOTE: For embargo/lease, attributes[:visibility] will be nil (see sanitize_params), so visibility will be validated as part of embargo/lease
        return true if attributes[:visibility].blank?

        # Validate against template's visibility requirements
        return true if validate_template_visibility(attributes[:visibility], template)

        env.curation_concern.errors.add(:visibility, 'Visibility specified does not match permission template visibility requirement for selected AdminSet.')
        false
      end

      # When specified, validate embargo is a future date that complies with AdminSet template requirements (if any)
      def validate_embargo(env, intention, attributes, template)
        return true unless intention.wants_embargo?

        embargo_release_date = parse_date(attributes[:embargo_release_date])

        # When embargo required, date must be in future AND matches any template requirements
        return true if valid_future_date?(env, embargo_release_date) &&
                       valid_template_embargo_date?(env, embargo_release_date, template) &&
                       valid_template_visibility_after_embargo?(env, attributes, template)

        env.curation_concern.errors.add(:visibility, 'When setting visibility to "embargo" you must also specify embargo release date.') if embargo_release_date.blank?
        false
      end

      # Validate an date attribute is in the future
      def valid_future_date?(env, date, attribute_name: :embargo_release_date)
        return true if date.present? && date.future?

        env.curation_concern.errors.add(attribute_name, "Must be a future date.")
        false
      end

      # Validate an embargo date against permission template restrictions
      def valid_template_embargo_date?(env, date, template)
        return true if template.blank?

        # Validate against template's release_date requirements
        return true if template.valid_release_date?(date)

        env.curation_concern.errors.add(:embargo_release_date, "Release date specified does not match permission template release requirements for selected AdminSet.")
        false
      end

      # Validate the post-embargo visibility against permission template requirements (if any)
      def valid_template_visibility_after_embargo?(env, attributes, template)
        # Validate against template's visibility requirements
        return true if validate_template_visibility(attributes[:visibility_after_embargo], template)

        env.curation_concern.errors.add(:visibility_after_embargo, "Visibility after embargo does not match permission template visibility requirements for selected AdminSet.")
        false
      end

      # Validate that a given visibility value satisfies template requirements
      def validate_template_visibility(visibility, template)
        return true if template.blank?

        template.valid_visibility?(visibility)
      end

      # Parse date from string. Returns nil if date_string is not a valid date
      def parse_date(date_string)
        datetime = Time.zone.parse(date_string) if date_string.present?
        return datetime.to_date unless datetime.nil?
        nil
      end

      # If they want a lease, we can assume it's valid
      def apply_lease(env, intention)
        return true unless intention.wants_lease?
        env.curation_concern.apply_lease(*intention.lease_params)
        # apply_lease returns true if there has been a change in the lease period,
        # otherwise it returns nil.  Since we want to continue processing, even when the date
        # does not change, we return true from this method.
        true
      end

      # If they want an embargo, we can assume it's valid
      def apply_embargo(env, intention)
        return true unless intention.wants_embargo?
        env.curation_concern.apply_embargo(*intention.embargo_params)
        # apply_embargo returns true if there has been a change in the embargo period,
        # otherwise it returns nil.  Since we want to continue processing, even when the date
        # does not change, we return true from this method.
        true
      end
    end
  end
end
