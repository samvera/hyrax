module Hyrax
  module CollectionTypes
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
        assigns_visibility: false
      }.freeze

      def self.create_collection_type(machine_id: DEFAULT_MACHINE_ID, title: DEFAULT_TITLE, options: {})
        opts = DEFAULT_OPTIONS.merge(options)
        Hyrax::CollectionType.create(machine_id: machine_id, title: title) do |c|
          c.description = opts[:description]
          c.nestable = opts[:nestable]
          c.discoverable = opts[:discoverable]
          c.sharable = opts[:sharable]
          c.allow_multiple_membership = opts[:allow_multiple_membership]
          c.require_membership = opts[:require_membership]
          c.assigns_workflow = opts[:assigns_workflow]
          c.assigns_visibility = opts[:assigns_visibility]
        end
      end
    end
  end
end
