# frozen_string_literal: true
RSpec.describe Hyrax::Workflow::ObjectInWorkflowDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryBot.valkyrie_create(:hyrax_work) }

  it { is_expected.not_to be_published }

  describe '#workflow_state' do
    it 'is unknown' do
      expect(decorator.workflow_state).to eq 'unknown'
    end
  end
end
