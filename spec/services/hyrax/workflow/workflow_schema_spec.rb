# frozen_string_literal: true
module Hyrax
  module Workflow
    RSpec.describe WorkflowSchema do
      subject(:schema) { described_class.new }

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

      it 'validates valid data by returning an empty error set' do
        expect(schema.call(valid_data).errors).to be_empty
      end

      it 'reports invalid data via the returned messages' do
        expect(schema.call(invalid_data).errors).not_to be_empty
      end

      describe 'notification names' do
        context 'with an uninitialized constant' do
          let(:notification_name) { 'FooBar' }

          it 'is invalid' do
            expect(schema.call(valid_data).errors).not_to be_empty
          end
        end

        context 'within a namespace' do
          before do
            class DoTheThing
            end
          end
          after { Hyrax::Workflow.send(:remove_const, :DoTheThing) }
          let(:notification_name) { 'Hyrax::Workflow::DoTheThing' }

          it 'returns an empty error set because valid' do
            expect(schema.call(valid_data).errors).to be_empty
          end
        end
      end
    end
  end
end
