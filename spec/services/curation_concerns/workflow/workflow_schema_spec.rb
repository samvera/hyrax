require 'spec_helper'

module CurationConcerns
  module Workflow
    RSpec.describe 'WorkflowSchema', no_clean: true do
      let(:valid_data) do
        {
          workflows: [
            {
              name: "valid",
              allows_access_grant: true,
              actions: [
                {
                  name: "finalize_digitization",
                  from_states: [{ names: ["pending"], roles: ['finalizing_digitation_review'] }],
                  transition_to: "metadata_review"
                }, {
                  name: "finalize_metadata",
                  from_states: [{ names: ["metadata_review"], roles: ['finalizing_metadata_review'] }],
                  transition_to: "final_review",
                  notifications: [
                    {
                      name: notification_name, notification_type: Sipity::Notification::NOTIFICATION_TYPE_EMAIL, to: ['finalizing_metadata_review']
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      let(:notification_name) { 'DoTheThing' }

      let(:invalid_data) do
        {
          workflows: [
            {
              actions: [
                { name: "finalize_digitization", from_states: [{ names: ["pending"], roles: [] }], transition_to: "metadata_review" }
              ]
            }
          ]
        }
      end

      before do
        class ::DoTheThing
        end
      end

      after do
        Object.send(:remove_const, :DoTheThing)
      end

      it 'validates valid data by returning an empty message' do
        expect(WorkflowSchema.call(valid_data).messages).to be_empty
      end

      it 'reports invalid data via the returned messages' do
        expect(WorkflowSchema.call(invalid_data).messages).not_to be_empty
      end

      describe 'notification names' do
        context 'with an uninitialized constant' do
          let(:notification_name) { 'FooBar' }
          it 'is invalid' do
            expect(WorkflowSchema.call(valid_data).messages).not_to be_empty
          end
        end

        context 'within a namespace' do
          before do
            class DoTheThing
            end
          end
          after { CurationConcerns::Workflow.send(:remove_const, :DoTheThing) }
          let(:notification_name) { 'CurationConcerns::Workflow::DoTheThing' }
          it 'returns an empty message because valid' do
            expect(WorkflowSchema.call(valid_data).messages).to be_empty
          end
        end
      end
    end
  end
end
