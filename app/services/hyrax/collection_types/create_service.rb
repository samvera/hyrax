# frozen_string_literal: true
module Hyrax
  module CollectionTypes
    # @api public
    #
    # Responsible for creating a CollectionType. If no params are given,the default user collection is assumed as defined by:
    #
    # * Hyrax::CollectionType::USER_COLLECTION_MACHINE_ID
    # * Hyrax::CollectionType::USER_COLLECTION_DEFAULT_TITLE
    # * DEFAULT_OPTIONS
    #
    # @see Hyrax:CollectionType
    #
    class CreateService
      DEFAULT_OPTIONS = {
        description: '',
        nestable: true,
        brandable: true,
        discoverable: true,
        sharable: true,
        share_applies_to_new_works: true,
        allow_multiple_membership: true,
        require_membership: false,
        assigns_workflow: false,
        assigns_visibility: false,
        badge_color: "#663333",
        participants: [{ agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE, agent_id: ::Ability.admin_group_name, access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS },
                       { agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE, agent_id: ::Ability.registered_group_name, access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS }]
      }.freeze

      USER_COLLECTION_MACHINE_ID = Hyrax::CollectionType::USER_COLLECTION_MACHINE_ID
      USER_COLLECTION_TITLE = Hyrax::CollectionType::USER_COLLECTION_DEFAULT_TITLE
      USER_COLLECTION_OPTIONS = {
        description: I18n.t('hyrax.collection_types.create_service.default_description'),
        nestable: true,
        brandable: true,
        discoverable: true,
        sharable: true,
        share_applies_to_new_works: false,
        allow_multiple_membership: true,
        require_membership: false,
        assigns_workflow: false,
        assigns_visibility: false,
        badge_color: "#705070",
        participants: [{ agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE, agent_id: ::Ability.admin_group_name, access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS },
                       { agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE, agent_id: ::Ability.registered_group_name, access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS }]
      }.freeze

      ADMIN_SET_MACHINE_ID = Hyrax::CollectionType::ADMIN_SET_MACHINE_ID
      ADMIN_SET_TITLE = Hyrax::CollectionType::ADMIN_SET_DEFAULT_TITLE
      ADMIN_SET_OPTIONS = {
        description: I18n.t('hyrax.collection_types.create_service.admin_set_description'),
        nestable: false,
        brandable: false,
        discoverable: false,
        sharable: true,
        share_applies_to_new_works: true,
        allow_multiple_membership: false,
        require_membership: true,
        assigns_workflow: true,
        assigns_visibility: true,
        badge_color: "#405060",
        participants: [{ agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE, agent_id: ::Ability.admin_group_name, access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS },
                       { agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE, agent_id: ::Ability.admin_group_name, access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS }]
      }.freeze

      # @api public
      #
      # Create a new collection type.
      #
      # @param machine_id [String]
      # @param title [String] short tag identifying the collection type
      # @param options [Hash] options to override DEFAULT_OPTIONS
      # @option options [String] :description a description to show the user when selecting the collection type
      # @option options [Boolean] :nestable if true, collections of this type can be nested
      # @option options [Boolean] :brandable if true, collections of this type can be branded
      # @option options [Boolean] :discoverable if true, collections of this type can be marked Public and found in search results
      # @option options [Boolean] :sharable if true, collections of this type can have participants added for :manage, :deposit, or :view access
      # @option options [Boolean] :share_applies_to_new_works if true, share participant permissions are applied to new works created in the collection
      # @option options [Boolean] :allow_multiple_membership if true, works can be members of multiple collections of this type
      # @option options [Boolean] :require_membership if true, all works must belong to at least one collection of this type.  When combined
      #   with allow_multiple_membership=false, works can belong to one and only one collection of this type.
      # @option options [Boolean] :assigns_workflow if true, collections of this type can be used to assign a workflow to a work
      # @option options [Boolean] :assigns_visibility if true, collections of this type can be used to assign initial visibility to a work
      # @option options [String] :badge_color a color for the badge to show the user when selecting the collection type
      # @return [Hyrax::CollectionType] the newly created collection type instance
      def self.create_collection_type(machine_id:, title:, options: {})
        opts = DEFAULT_OPTIONS.merge(options).except(:participants)
        ct = Hyrax::CollectionType.create!(opts.merge(machine_id: machine_id, title: title))
        participants = options[:participants].presence || DEFAULT_OPTIONS[:participants]
        add_participants(ct.id, participants)
        ct
      end

      # @api public
      #
      # Create admin set collection type.
      #
      # @return [Hyrax::CollectionType] the newly created admin set collection type instance
      def self.create_admin_set_type
        create_collection_type(machine_id: ADMIN_SET_MACHINE_ID, title: ADMIN_SET_TITLE, options: ADMIN_SET_OPTIONS)
      end

      # @api public
      #
      # Create user collection type.
      #
      # @return [Hyrax::CollectionType] the newly created user collection type instance
      def self.create_user_collection_type
        create_collection_type(machine_id: USER_COLLECTION_MACHINE_ID, title: USER_COLLECTION_TITLE, options: USER_COLLECTION_OPTIONS)
      end

      # @api public
      #
      # Add the default participants to a collection_type.
      #
      # @param collection_type_id [Integer] the id of the collection type
      # @note Several checks get the user's groups from the user's ability.  The same values can be retrieved directly from a passed in ability.
      #   If calling from Abilities, pass the ability.  If you try to get the ability from the user, you end up in an infinit loop.
      def self.add_default_participants(collection_type_id)
        return unless collection_type_id
        default_participants = [{  agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
                                   agent_id: ::Ability.admin_group_name,
                                   access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS },
                                { agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE,
                                  agent_id: ::Ability.registered_group_name,
                                  access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS }]
        add_participants(collection_type_id, default_participants)
      end

      ##
      # @api public
      #
      # Add a participants to a collection_type.
      #
      # @param collection_type_id [Integer] the id of the collection type
      # @param participants [Array<Hash>] each element holds agent_type, agent_id,
      #   and access for a participant to be added
      #
      # @raise [InvalidParticipantError] if a participant is missing an
      #   `agent_type`, `agent_id`, or `access`.
      def self.add_participants(collection_type_id, participants)
        raise(InvalidParticipantError, participants) unless
          participants.all? { |p| p.key?(:agent_type) && p.key?(:agent_id) && p.key?(:access) }

        participants.each do |p|
          Hyrax::CollectionTypeParticipant.create!(hyrax_collection_type_id: collection_type_id, agent_type: p.fetch(:agent_type), agent_id: p.fetch(:agent_id), access: p.fetch(:access))
        end
      rescue InvalidParticipantError => error
        Hyrax.logger.error "Participants not created for collection type " \
                           " #{collection_type_id}: #{error.message}"
        raise error
      end

      ##
      # An error class for the case that invalid/incomplete participants are
      # added to a collection type.
      class InvalidParticipantError < RuntimeError
        attr_reader :participants

        def initialize(participants)
          @participants = participants
        end

        ##
        # @return [String]
        def message
          @participants.map do |participant|
            "#{participant[:agent_type]}, #{participant[:agent_id]}, #{participant[:access]}"
          end.join("--\n")
        end
      end
    end
  end
end
