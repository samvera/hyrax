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
      DEFAULT_MACHINE_ID = Hyrax::CollectionType::USER_COLLECTION_MACHINE_ID
      DEFAULT_TITLE = Hyrax::CollectionType::USER_COLLECTION_DEFAULT_TITLE
      DEFAULT_OPTIONS = {
        description: 'A User Collection can be created by any user to organize their works.',
        nestable: true,
        discoverable: true,
        sharable: true,
        allow_multiple_membership: true,
        require_membership: false,
        assigns_workflow: false,
        assigns_visibility: false,
        participants: [{ agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE, agent_id: ::Ability.admin_group_name, access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS },
                       { agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE, agent_id: ::Ability.registered_group_name, access: Hyrax::CollectionTypeParticipant::CREATE_ACCESS }]
      }.freeze

      # @api public
      #
      # Create a new collection type.
      #
      # @param machine_id [String]
      # @param title [String] short tag identifying the collection type
      # @param options [Hash] options to override DEFAULT_OPTIONS
      # @option options [String] :description a description to show the user when selecting the collection type
      # @option options [True | False] :nestable if true, collections of this type can be nested
      # @option options [True | False] :discoverable if true, collections of this type can be marked Public and found in search results
      # @option options [True | False] :sharable if true, collections of this type can have participants added for :manage, :deposit, or :view access
      # @option options [True | False] :allow_multiple_membership if true, works can be members of multiple collections of this type
      # @option options [True | False] :require_membership if true, all works must belong to at least one collection of this type.  When combined
      #   with allow_multiple_membership=false, works can belong to one and only one collection of this type.
      # @option options [True | False] :assigns_workflow if true, collections of this type can be used to assign a workflow to a work
      # @option options [True | False] :assigns_visibility if true, collections of this type can be used to assign initial visibility to a work
      # @return [Hyrax::CollectionType] the newly created collection type instance
      def self.create_collection_type(machine_id: DEFAULT_MACHINE_ID, title: DEFAULT_TITLE, options: {})
        opts = DEFAULT_OPTIONS.merge(options)
        ct = Hyrax::CollectionType.create!(machine_id: machine_id, title: title) do |c|
          c.description = opts[:description]
          c.nestable = opts[:nestable]
          c.discoverable = opts[:discoverable]
          c.sharable = opts[:sharable]
          c.allow_multiple_membership = opts[:allow_multiple_membership]
          c.require_membership = opts[:require_membership]
          c.assigns_workflow = opts[:assigns_workflow]
          c.assigns_visibility = opts[:assigns_visibility]
        end
        add_participants(ct.id, opts[:participants])
        ct
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

      # @api public
      #
      # Add a participants to a collection_type.
      #
      # @param collection_type_id [Integer] the id of the collection type
      # @param participants [Array<Hash>] each element holds agent_type, agent_id, and access for a participant to be added
      def self.add_participants(collection_type_id, participants)
        return unless collection_type_id && participants.count > 0
        participants.each do |p|
          begin
            agent_type = p.fetch(:agent_type)
            agent_id = p.fetch(:agent_id)
            access = p.fetch(:access)
            Hyrax::CollectionTypeParticipant.create!(hyrax_collection_type_id: collection_type_id, agent_type: agent_type, agent_id: agent_id, access: access)
          rescue
            Rails.logger.error "Participant not created for collection type #{collection_type_id}: #{agent_type}, #{agent_id}, #{access}\n"
          end
        end
      end
    end
  end
end
