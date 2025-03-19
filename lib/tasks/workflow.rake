# frozen_string_literal: true
namespace :hyrax do
  namespace :workflow do
    desc "Load workflow configuration into the database"
    task load: :environment do
      logger = Hyrax.logger || Logger.new(STDOUT, level: Logger::DEBUG)
      Hyrax::Workflow::WorkflowImporter.load_workflows(logger: logger)
      errors = Hyrax::Workflow::WorkflowImporter.load_errors
      abort("Failed to process all workflows:\n  #{errors.join('\n  ')}") unless errors.empty?
    end
  end
end
