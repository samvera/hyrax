# frozen_string_literal: true

RSpec.describe Hyrax::AdminSetSelectionPresenter do
  subject(:presenter) { described_class.new(admin_sets: admin_sets) }

  let(:admin_sets) do
    [FactoryBot.valkyrie_create(:hyrax_admin_set, title: 'first'),
     FactoryBot.valkyrie_create(:hyrax_admin_set, title: 'second'),
     FactoryBot.valkyrie_create(:hyrax_admin_set, title: 'third')]
  end

  describe '#select_options' do
    it 'builds out the options for a select dropdown' do
      expect(presenter.select_options)
        .to contain_exactly ["first", admin_sets[0].id, an_instance_of(Hash)],
                            ["second", admin_sets[1].id, an_instance_of(Hash)],
                            ["third", admin_sets[2].id, an_instance_of(Hash)]
    end
  end

  describe described_class::OptionsEntry do
    subject(:entry) { described_class.new(admin_set: admin_set) }

    let(:admin_set) do
      FactoryBot.valkyrie_create(:hyrax_admin_set, title: 'first')
    end

    its(:id) { is_expected.to eq admin_set.id }

    describe '#data' do
      it 'is a hash' do
        expect(entry.data)
          .to include 'data-release-no-delay' => true,
                      'data-visibility' => 'restricted'
      end
    end

    describe '#label' do
      it 'is the title' do
        expect(entry.label).to eq 'first'
      end
    end
  end
end
