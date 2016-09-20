require 'dry/validation'

module Sipity
  # Responsible for describing the JSON schema for a Workflow
  WorkflowSchema = Dry::Validation.Schema do
    required(:work_types).each do
      required(:name).filled(:str?)
      required(:actions).each do
        required(:name).filled(:str?)
        required(:from_states).each do
          required(:name).filled(:str?)
          required(:roles) { array? { each(:str?) } }
        end
        required(:transition_to).filled(:str?)
      end
    end
  end
end
