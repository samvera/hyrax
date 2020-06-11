# frozen_string_literal: true
require "spec_helper"

module Hyrax
  module Workflow
    RSpec.describe WorkflowPermissionsGenerator do
      let(:workflow) { Sipity::Workflow.new(name: 'Hello') }
      let(:workflow_permissions_configuration) do
        [
          { role: "work_submitting" },
          { role: "etd_reviewing" }
        ]
      end

      before do
        workflow_permissions_configuration.each do |config|
          Sipity::Role.find_or_create_by!(name: config.fetch(:role))
        end
      end

      it 'exposes .call as a convenience method' do
        expect_any_instance_of(described_class).to receive(:call)
        described_class.call(workflow: workflow, workflow_permissions_configuration: workflow_permissions_configuration)
      end

      subject { described_class.new(workflow: workflow, workflow_permissions_configuration: workflow_permissions_configuration) }

      it 'will create groups and assign permissions accordingly' do
        allow_any_instance_of(PermissionGenerator).to receive(:call)
        subject.call

        # And it won't keep creating things
        [:update_attribute, :update_attributes, :update_attributes!, :save, :save!, :update, :update!].each do |method_names|
          expect_any_instance_of(ActiveRecord::Base).not_to receive(method_names)
        end
        subject.call
      end
    end
  end
end
