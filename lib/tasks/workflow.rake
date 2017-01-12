namespace :hyrax do
  namespace :workflow do
    desc "Load workflow configuration into the database"
    task load: :environment do
      Hyrax::Workflow::WorkflowImporter.load_workflows
      errors = Hyrax::Workflow::WorkflowImporter.load_errors
      abort("Failed to process all workflows:\n  #{errors.join('\n  ')}") unless errors.empty?
    end
  end
end
