# frozen_string_literal: true

RSpec.describe Hyrax::PageTitleDecorator do
  subject(:decorated) { described_class.new(work) }
  let(:work) { build(:hyrax_work) }

  describe '#title' do
    it 'returns "No Title"' do
      expect(decorated.title).to eq 'No Title'
    end

    context 'with a title' do
      let(:work) { build(:hyrax_work, title: 'comet in moominland') }

      it 'returns the title' do
        expect(decorated.title).to eq 'comet in moominland'
      end
    end

    context 'with multiple titles' do
      let(:work) do
        build(:hyrax_work, title: ['first title', 'second title'])
      end

      it 'returns a string with both titles' do
        expect(decorated.title).to eq 'first title | second title'
      end
    end
  end

  describe '#page_title' do
    it 'gives a string' do
      expect(decorated.page_title).to be_a String
    end
  end
end
