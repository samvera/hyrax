class Hyrax::WorkChangeSet < Valkyrie::ChangeSet
  class_attribute :workflow_class, :exclude_fields, :primary_terms, :secondary_terms
  # Which fields show above the fold.
  self.primary_terms = [:title, :creator, :keyword, :rights_statement]
  # Don't create accessors for these fields
  self.exclude_fields = [:internal_resource, :id, :read_groups, :read_users, :edit_users, :edit_groups]

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
end
