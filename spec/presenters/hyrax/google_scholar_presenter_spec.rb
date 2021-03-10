# frozen_string_literal: true

RSpec.describe Hyrax::GoogleScholarPresenter do
  subject(:presenter) { described_class.new(work) }
  let(:work) { FactoryBot.build(:monograph, title: 'On Moomins') }

  describe '#scholarly?' do
    it { is_expected.to be_scholarly }

    context 'when the decorated object says it is not scholarly' do
      let(:work) { double('scholarly?': false) }

      it { is_expected.not_to be_scholarly }
    end
  end

  describe '#authors' do
    let(:work) { FactoryBot.build(:monograph, creator: ['Tove', 'Lars']) }

    it 'gives an array of the authors' do
      expect(presenter.authors).to eq ['Tove', 'Lars']
    end

    context 'if the object provides ordered authors' do
      let(:work) { double(ordered_authors: ['Tove', 'Lars']) }

      it 'gives an array of the authors' do
        expect(presenter.authors).to eq ['Tove', 'Lars']
      end
    end
  end

  describe '#description' do
    it 'gives the title' do # why?
      expect(presenter.description).to eq 'On Moomins'
    end

    context 'with a description' do
      let(:work) { FactoryBot.build(:monograph, description: ['a short abstract']) }

      it 'gives the title' do # why?
        expect(presenter.description).to eq 'a short abstract'
      end
    end

    context 'with a long description' do
      let(:work) { FactoryBot.build(:monograph, description: [description]) }
      let(:description) { Array.new(1000) { 'a' }.join('') }

      it 'truncates the description' do
        expect(presenter.description.length).to eq 200
      end
    end
  end

  describe '#keywords' do
    let(:work) { FactoryBot.build(:monograph, keyword: ['one', 'two', 'three']) }

    it 'lists the keywords semicolon delimeted' do
      expect(presenter.keywords).to eq 'one; two; three'
    end
  end

  describe '#publication_date' do
    let(:work) { FactoryBot.build(:monograph, date_created: ['2021', '2024']) }

    it 'gives exactly one publication date' do
      expect(presenter.publication_date).to eq '2021'
    end
  end

  describe '#publisher' do
    let(:work) { FactoryBot.build(:monograph, publisher: ['Knopf', 'Macmillan', 'Sage']) }

    it 'lists the publishers semicolon delimeted' do
      expect(presenter.publisher).to eq 'Knopf; Macmillan; Sage'
    end
  end

  describe '#title' do
    it 'gives title as a string' do
      expect(presenter.title).to eq 'On Moomins'
    end
  end
end
