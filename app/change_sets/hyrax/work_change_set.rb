class Hyrax::WorkChangeSet < Valkyrie::ChangeSet
  class_attribute :workflow_class, :exclude_fields, :primary_terms, :secondary_terms
  # Which fields show above the fold.
  self.primary_terms = [:title, :creator, :keyword, :rights_statement]
  # Don't create accessors for these fields
  self.exclude_fields = [:internal_resource, :id, :read_groups, :read_users, :edit_users, :edit_groups]

  # A collection to add this work to after it's created
  property :add_works_to_collection, virtual: true

  class << self
    def work_klass
      name.sub(/ChangeSet$/, '').constantize
    end

    def autocreate_fields!
      self.fields = work_klass.schema.keys + [:resource_type] - exclude_fields
      self.secondary_terms = fields - primary_terms
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
