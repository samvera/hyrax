module Hyrax
  class WorkChangeSet < Valkyrie::ChangeSet
    class_attribute :workflow_class, :exclude_fields, :primary_terms, :secondary_terms
    delegate :human_readable_type, to: :resource

    # Which fields show above the fold.
    self.primary_terms = [:title, :creator, :keyword, :rights_statement]
    self.secondary_terms = [:contributor, :description, :license, :publisher,
                            :date_created, :subject, :language, :identifier,
                            :based_near, :related_url, :source]

    # Don't create accessors for these fields
    self.exclude_fields = [:internal_resource, :id, :read_groups, :read_users, :edit_users, :edit_groups]

    # Used for searching
    property :search_context, virtual: true, multiple: false, required: false

    # TODO: Figure out where to persist these fields
    property :embargo_release_date, virtual: true
    property :lease_expiration_date, virtual: true
    property :visibility, virtual: true
    property :visibility_during_embargo, virtual: true
    property :visibility_after_embargo, virtual: true
    property :visibility_during_lease, virtual: true
    property :visibility_after_lease, virtual: true

    # TODO: this should be validated
    property :agreement_accepted, virtual: true

    # TODO: how do we get an etag?
    property :version, virtual: true

    collection :permissions, virtual: true
    collection :work_members, virtual: true

    validate :validate_lease
    validate :validate_embargo
    validate :validate_release_type
    validate :validate_visibility

    class << self
      def work_klass
        name.sub(/ChangeSet$/, '').constantize
      end

      def autocreate_fields!
        self.fields = work_klass.schema.keys + [:resource_type] - [:internal_resource, :id, :read_groups, :read_users, :edit_users, :edit_groups]
      end
    end

    def prepopulate!
      prepopulate_permissions
      prepopulate_admin_set_id
      prepopulate_work_members
      super.tap do
        @_changes = Disposable::Twin::Changed::Changes.new
      end
    end

    # We just need to respond to this method so that the rails nested form builder will work.
    def permissions_attributes=
      # nop
    end

    # We just need to respond to this method so that the rails nested form builder will work.
    def work_members_attributes=
      # nop
    end

    def page_title
      if resource.persisted?
        [resource.to_s, "#{resource.human_readable_type} [#{resource.to_param}]"]
      else
        ["New #{resource.human_readable_type}"]
      end
    end

    # Do not display additional fields if there are no secondary terms
    # @return [Boolean] display additional fields on the form?
    def display_additional_fields?
      secondary_terms.any?
    end

    # Get a list of collection id/title pairs for the select form
    def collections_for_select
      collection_service = CollectionsService.new(search_context)
      CollectionOptionsPresenter.new(collection_service).select_options(:edit)
    end

    # Select collection(s) based on passed-in params and existing memberships.
    # @return [Array] a list of collection identifiers
    def member_of_collections(collection_ids)
      (member_of_collection_ids + Array.wrap(collection_ids)).uniq
    end

    private

      def wants_lease?
        visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE
      end

      def wants_embargo?
        visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
      end

      def template
        @template ||= PermissionTemplate.find_by!(admin_set_id: admin_set_id) if admin_set_id.present?
      end

      # admin_set_id is required on the client, otherwise simple_form renders a blank option.
      # however it isn't a required field for someone to submit via json.
      # Set the first admin_set they have access to.
      def prepopulate_admin_set_id
        admin_set = Hyrax::AdminSetService.new(search_context).search_results(:deposit).first
        self.admin_set_id = admin_set && admin_set.id
      end

      def prepopulate_work_members
        self.work_members = Hyrax::Queries.find_members(resource: resource).select(&:work?)
      end

      def prepopulate_permissions
        self.permissions = resource.edit_users.map { |key| PermissionChangeSet.new(Permission.new, agent_name: key, access: 'edit', type: 'person') } +
                           resource.read_users.map { |key| PermissionChangeSet.new(Permission.new, agent_name: key, access: 'read', type: 'person') } +
                           resource.edit_groups.map { |key| PermissionChangeSet.new(Permission.new, agent_name: key, access: 'edit', type: 'group') } +
                           resource.read_groups.map { |key| PermissionChangeSet.new(Permission.new, agent_name: key, access: 'read', type: 'group') }
      end

      def validate_lease
        # Validate that a lease is allowed by AdminSet's PermissionTemplate
        return unless wants_lease?

        # Leases are only allowable if a template doesn't require a release period or have any specific visibility requirement
        # (Note: permission template release/visibility options do not support leases)
        unless template.present? && (template.release_period.present? || template.visibility.present?)
          date = parse_date(lease_expiration_date)
          return if valid_future_date?(date, attribute_name: :lease_expiration_date)
          errors.add(:visibility, 'When setting visibility to "lease" you must also specify lease expiration date.')
        end

        errors.add(:visibility, 'Lease option is not allowed by permission template for selected AdminSet.')
      end

      # When specified, validate embargo is a future date that complies with AdminSet template requirements (if any)
      def validate_embargo
        return unless wants_embargo?
        date = parse_date(embargo_release_date)

        # When embargo is required, date must be in future AND match any template requirements
        return if valid_future_date?(date) &&
                  valid_template_embargo_date?(date) &&
                  valid_template_visibility_after_embargo?

        errors.add(:visibility, 'When setting visibility to "embargo" you must also specify embargo release date.') if date.blank?
      end

      # Validate an date attribute is in the future
      def valid_future_date?(date, attribute_name: :embargo_release_date)
        return true if date.present? && date.future?

        errors.add(attribute_name, "Must be a future date.")
        false
      end

      # Validate an embargo date against permission template restrictions
      def valid_template_embargo_date?(date)
        return true if template.blank?

        # Validate against template's release_date requirements
        return true if template.valid_release_date?(date)

        errors.add(:embargo_release_date, "Release date specified does not match permission template release requirements for selected AdminSet.")
        false
      end

      # Validate the post-embargo visibility against permission template requirements (if any)
      def valid_template_visibility_after_embargo?
        # Validate against template's visibility requirements
        return true if validate_template_visibility(visibility_after_embargo)

        errors.add(:visibility_after_embargo, "Visibility after embargo does not match permission template visibility requirements for selected AdminSet.")
        false
      end

      # Validate that a given visibility value satisfies template requirements
      def validate_template_visibility(visibility)
        return true if template.blank?

        template.valid_visibility?(visibility)
      end

      # Parse date from string. Returns nil if date_string is not a valid date
      def parse_date(date_string)
        datetime = Time.zone.parse(date_string) if date_string.present?
        return datetime.to_date unless datetime.nil?
        nil
      end

      # Validate the selected release settings against template, checking for when embargoes/leases are not allowed
      def validate_release_type
        # It's valid as long as embargo is not specified when a template requires no release delays
        return unless wants_embargo? && template.present? && template.release_no_delay?

        errors.add(:visibility, 'Visibility specified does not match permission template "no release delay" requirement for selected AdminSet.')
      end

      # Validate visibility complies with AdminSet template requirements
      def validate_visibility
        return if visibility.blank? || wants_embargo? || wants_lease? || validate_template_visibility(visibility)

        errors.add(:visibility, 'Visibility specified does not match permission template visibility requirement for selected AdminSet.')
      end
  end
end
