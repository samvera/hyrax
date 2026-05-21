# frozen_string_literal: true

RSpec.describe Hyrax::PermalinkPath do
  describe '.call' do
    let(:work_path) { '/concern/generic_works/abc-123' }
    let(:collection_path) { '/collections/abc-123' }

    context 'with a work resource (collection? returns false)' do
      let(:work) { Struct.new(:collection?).new(false) }

      it 'uses the host app route helpers' do
        expect(Rails.application.routes.url_helpers).to receive(:polymorphic_path).with(work).and_return(work_path)
        expect(Hyrax::Engine.routes.url_helpers).not_to receive(:polymorphic_path)
        expect(described_class.call(work)).to eq(work_path)
      end
    end

    context 'with a collection resource (collection? returns true)' do
      let(:collection) { Struct.new(:collection?).new(true) }

      it 'uses the Hyrax engine route helpers' do
        expect(Hyrax::Engine.routes.url_helpers).to receive(:polymorphic_path).with(collection).and_return(collection_path)
        expect(Rails.application.routes.url_helpers).not_to receive(:polymorphic_path)
        expect(described_class.call(collection)).to eq(collection_path)
      end
    end

    context 'with an object that does not respond to collection?' do
      let(:object) { Object.new }

      it 'falls back to the host app route helpers' do
        expect(Rails.application.routes.url_helpers).to receive(:polymorphic_path).with(object).and_return(work_path)
        expect(described_class.call(object)).to eq(work_path)
      end
    end
  end
end
