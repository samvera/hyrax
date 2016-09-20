require "spec_helper"

RSpec.describe CurationConcerns::WorkflowImporter do
  let(:path) { double(read: json) }
  let(:json) do
    doc = <<-HERE
    {
      "work_types": [
        {
          "name": "ulra_submission",
          "strategy_permissions": [{
            "group": "ULRA Review Committee",
            "role": "ulra_reviewing"
          }],
          "actions": [{
            "name": "start_a_submission",
            "transition_to": "new",
            "emails": [{
              "name": "confirmation_of_ulra_submission_started",
              "to": "creating_user"
            },{
              "name": "faculty_assigned_for_ulra_submission",
              "to": "advising"
            }]
          },{
            "name": "start"
          }],
          "action_analogues": [{
            "action": "start_a_submission", "analogous_to": "start"
          }],
          "state_emails": [{
            "state": "new",
            "reason": "processing_hook_triggered",
            "emails": [{
              "name": "student_has_indicated_attachments_are_complete",
              "to": "ulra_reviewing"
            }]
          }]
        }
      ]
    }
    HERE
    doc.strip
  end
  let(:validator) { double(call: true) }

  subject { described_class.new(data: {}, validator: validator) }

  its(:default_validator) { is_expected.to respond_to(:call) }
  its(:default_schema) { is_expected.to respond_to(:call) }

  it 'exposes .generate_from_json_file as a convenience method' do
    expect_any_instance_of(described_class).to receive(:call)
    described_class.generate_from_json_file(path: path, validator: validator)
  end

  it 'validates the data against the schema' do
    subject
    expect(validator).to have_received(:call).with(data: subject.send(:data), schema: subject.send(:schema))
  end

  context '.generate_from_json_file' do
    let(:path) { Rails.root.join('config/workflows/generic_work_workflow.json').to_s }

    it 'will load the file and parse as JSON' do
      expect_any_instance_of(described_class).to receive(:call)
      described_class.generate_from_json_file(path: path)
    end
  end

  context 'data generation' do
    it 'creates the requisite data' do
      expect(CurationConcerns::EmailNotificationGenerator).to receive(:call).and_call_original.exactly(3).times
      expect_any_instance_of(CurationConcerns::WorkflowPermissionsGenerator).to receive(:call)
      expect(CurationConcerns::SipityActionsGenerator).to receive(:call).and_call_original
      expect do
        described_class.generate_from_json_file(path: path)
      end.to change { Sipity::Workflow.count }.by(1)
    end
  end
end
