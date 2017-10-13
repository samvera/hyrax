class Hyrax::WorkChangeSet < Valkyrie::ChangeSet
  class_attribute :workflow_class

  class << self
    def autocreate_fields!
      work_klass = name.sub(/ChangeSet$/, '').constantize
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
end
