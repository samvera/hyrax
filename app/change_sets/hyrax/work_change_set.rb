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

    # A collection to add this work to after it's created
    property :add_works_to_collection, virtual: true

    class << self
      def work_klass
        name.sub(/ChangeSet$/, '').constantize
      end

      def autocreate_fields!
        self.fields = work_klass.schema.keys + [:resource_type] - [:internal_resource, :id, :read_groups, :read_users, :edit_users, :edit_groups]
      end
    end

    def self.apply_workflow(workflow)
      self.workflow_class = workflow
      include(Valhalla::ChangeSetWorkflow)
    end

    def prepopulate!
      super.tap do
        @_changes = Disposable::Twin::Changed::Changes.new
      end
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

    # admin_set_id is required on the client, otherwise simple_form renders a blank option.
    # however it isn't a required field for someone to submit via json.
    # Set the first admin_set they have access to.
    def admin_set_id
      admin_set = Hyrax::AdminSetService.new(search_context).search_results(:deposit).first
      admin_set && admin_set.id
    end
  end

  # when the add_works_to_collection parameter is set, they mean to create
  # a new work and add it to that collection.
  def member_of_collections
    base = Hyrax::Queries.find_references_by(resource: model, property: :member_of_collection_ids)
    return base unless add_works_to_collection
    base + [Hyrax::Queries.find_collection(id: add_works_to_collection)]
  end

  # backs the child work search element
  # @return [NilClass]
  def find_child_work; end

  def member_of_collections_json
    member_of_collections.map do |coll|
      {
        id: coll.id,
        label: coll.to_s,
        path: @controller.url_for(coll)
      }
    end.to_json
  end

  def work_members_json
    work_members.map do |child|
      {
        id: child.id,
        label: child.to_s,
        path: @controller.url_for(child)
      }
    end.to_json
  end
end
