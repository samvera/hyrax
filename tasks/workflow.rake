namespace :curation_concerns do
  namespace :workflow do
    desc "Load workflow configuration into the database"
    task load: :environment do
      Dir.glob("config/workflows/*.json") do |config|
        CurationConcerns::Workflow::WorkflowImporter.generate_from_json_file(path: config)
      end
    end
  end
end
