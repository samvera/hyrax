require 'spec_helper'

module CurationConcerns
  module Workflow
    RSpec.describe 'WorkflowSchema', no_clean: true do
      it 'will validate valid data by returning an empty message' do
        valid_data = {
          work_types: [{
            name: "valid",
            actions: [{
              name: "finalize_digitization",
              from_states: [{ names: ["pending"], roles: ['finalizing_digitation_review'] }],
              transition_to: "metadata_review"
            }, {
              name: "finalize_metadata",
              from_states: [{ names: ["metadata_review"], roles: ['finalizing_metadata_review'] }],
              transition_to: "final_review",
              notifications: [{
                name: 'thank_you', notification_type: 'email', to: ['finalizing_metadata_review']
              }]
            }]
          }]
        }
        expect(WorkflowSchema.call(valid_data).messages).to be_empty
      end

      it 'will report invalid data via the returned messages' do
        invalid_data = {
          work_types: [{
            actions: [
              { name: "finalize_digitization", from_states: [{ names: ["pending"], roles: [] }], transition_to: "metadata_review" }
            ]
          }]
        }
        expect(WorkflowSchema.call(invalid_data).messages).to_not be_empty
      end
    end
  end
end
