# frozen_string_literal: true

RSpec.describe Hyrax::ValkyrieCanCanAdapter do
  describe '.find' do
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work) }

    it 'raises an ObjectNotFoundError' do
      expect { described_class.find(work.class, 'MISSING_ID') }
        .to raise_error Hyrax::ObjectNotFoundError
    end

    it 'finds a work' do
      expect(described_class.find(work.class, work.id).id)
        .to eq work.id
    end
  end

  describe '.for_class' do
    let(:subclass) { Class.new(Hyrax::Resource) }

    it 'is true for Hyrax::Resource' do
      expect(described_class.for_class?(Hyrax::Resource)).to eq true
    end

    it 'is true for Hyrax::Resource subclass' do
      expect(described_class.for_class?(subclass)).to eq true
    end
  end
end
