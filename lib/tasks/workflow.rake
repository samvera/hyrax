namespace :hyrax do
  namespace :workflow do
    desc "Load workflow configuration into the database"
    task load: :environment do
      Hyrax::Workflow::WorkflowImporter.load_workflows
    end
  end
end
