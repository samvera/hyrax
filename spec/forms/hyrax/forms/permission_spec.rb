# frozen_string_literal: true

RSpec.describe Hyrax::Forms::Permission do
  subject(:form) { described_class.new(Hyrax::Permission.new(agent: agent, mode: :edit)).tap(&:prepopulate!) }

  describe '#to_hash' do
    context 'with a group' do
      let(:agent) { 'group/managers' }

      it 'matches Hydra::AccessControls::Permission, with no group prefix' do
        expect(form.to_hash).to eq(name: 'managers', type: 'group', access: 'edit')
      end
    end

    context 'with a user' do
      let(:agent) { 'carol@example.com' }

      it { expect(form.to_hash).to eq(name: 'carol@example.com', type: 'person', access: 'edit') }
    end
  end
end
