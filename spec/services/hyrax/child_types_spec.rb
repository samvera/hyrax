# frozen_string_literal: true

RSpec.describe Hyrax::ChildTypes do
  subject(:child_types) { described_class.new(types) }
  let(:types)           { [GenericWork] }

  describe '.for' do
    let(:parent) { Hyrax::Test::SimpleWork }

    it 'can have itself as a child by default' do
      expect(described_class.for(parent: parent)).to contain_exactly(parent)
    end

    context 'with an ActiveFedora work', :active_fedora do
      let(:parent) { GenericWork }

      it 'gives the configured valid_child_concerns' do
        expect(described_class.for(parent: parent)).to contain_exactly(*parent.valid_child_concerns)
      end
    end
  end

  describe '#types' do
    it 'returns the initialized types' do
      expect(child_types.types).to contain_exactly(*types)
    end
  end

  describe '#to_a' do
    it 'returns the initialized types' do
      expect(child_types.to_a).to contain_exactly(*types)
    end
  end
end
