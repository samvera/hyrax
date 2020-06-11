# frozen_string_literal: true
module Hyrax
  module Workflow
    RSpec.describe NotificationConfigurationParameter do
      describe '#build_from_workflow_action_configuration' do
        let(:config) do
          {
            name: 'name_of_notification', notification_type: Sipity::Notification::NOTIFICATION_TYPE_EMAIL,
            to: ['role_name_to'], cc: ['role_name_cc'], bcc: ['role_name_bcc']
          }
        end

        it 'will build based on the given action' do
          expected = described_class.new scope: 'name_of_action',
                                         reason: Sipity::NotifiableContext::REASON_ACTION_IS_TAKEN,
                                         recipients: { to: config.fetch(:to), cc: config.fetch(:cc), bcc: config.fetch(:bcc) },
                                         notification_name: config.fetch(:name),
                                         notification_type: config.fetch(:notification_type)
          actual = described_class.build_from_workflow_action_configuration(workflow_action: 'name_of_action', config: config)
          expect(actual).to eq(expected)
        end
      end
    end
  end
end
