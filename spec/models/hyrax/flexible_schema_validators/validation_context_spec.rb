# frozen_string_literal: true

RSpec.describe Hyrax::FlexibleSchemaValidators::ValidationContext do
  subject(:context) { described_class.new(profile: profile) }

  describe '#properties' do
    context 'when the profile declares properties' do
      let(:profile) { { 'properties' => { 'title' => { 'type' => 'string' } } } }

      it 'returns them' do
        expect(context.properties).to eq('title' => { 'type' => 'string' })
      end
    end

    context 'when a property is not a hash' do
      let(:profile) { { 'properties' => { 'title' => { 'type' => 'string' }, 'broken' => 'nope' } } }

      it 'rejects the malformed entry' do
        expect(context.properties.keys).to contain_exactly('title')
      end
    end

    context 'when the profile declares no properties' do
      let(:profile) { {} }

      it { expect(context.properties).to eq({}) }
    end
  end

  describe '#class_names' do
    context 'when the profile declares classes' do
      let(:profile) { { 'classes' => { 'Monograph' => {}, 'Hyrax::FileSet' => {} } } }

      it 'returns the keys' do
        expect(context.class_names).to contain_exactly('Monograph', 'Hyrax::FileSet')
      end
    end

    context 'when the profile declares no classes' do
      let(:profile) { {} }

      it { expect(context.class_names).to eq [] }
    end
  end
end
