# frozen_string_literal: true

RSpec.describe Hyrax::ContextualPath, valkyrie_adapter: :test_adapter do
  subject(:contextual_path) { described_class.new(object, parent) }
  let(:object) { FactoryBot.valkyrie_create(:hyrax_file_set) }
  let(:parent) { FactoryBot.valkyrie_create(:hyrax_work) }

  describe '#show' do
    it 'gives the path nested under a parent' do
      expect(contextual_path.show)
        .to eq "/concern/parent/#{parent.id}/file_sets/#{object.id}"
    end

    context 'with nil parent' do
      let(:parent) { nil }

      it 'gives just the path for the object' do
        expect(contextual_path.show).to eq "/concern/file_sets/#{object.id}"
      end
    end
  end
end
