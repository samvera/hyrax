module CurationConcerns
  module Workflow
    # Responsible for describing the JSON schema for a Workflow
    WorkflowSchema = Dry::Validation.Schema do
      required(:work_types).each do
        required(:name).filled(:str?)
        required(:actions).each do
          required(:name).filled(:str?)
          required(:from_states).each do
            required(:names) { array? { each(:str?) } }
            required(:roles) { array? { each(:str?) } }
          end
          required(:transition_to).filled(:str?)
          optional(:notifications).each do
            required(:name).value(format?: /\A[a-z|_]+\Z/i)
            required(:notification_type).value(included_in?: Sipity::Notification.valid_notification_types)
            required(:to) { array? { each(:str?) } }
            optional(:cc) { array? { each(:str?) } }
            optional(:bcc) { array? { each(:str?) } }
          end
        end
      end
    end
  end
end
