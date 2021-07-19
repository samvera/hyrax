# frozen_string_literal: true

RSpec.describe Hyrax::AdminSetSelectionPresenter do
  subject(:presenter) { Hyrax::AdminSetSelectionPresenter.new(admin_sets: admin_sets) }

  let(:admin_sets) do
    [FactoryBot.valkyrie_create(:hyrax_admin_set, title: 'first'),
     FactoryBot.valkyrie_create(:hyrax_admin_set, title: 'second'),
     FactoryBot.valkyrie_create(:hyrax_admin_set, title: 'third')]
  end

  describe '#select_options' do
    it 'builds out the options for a select dropdown' do
      expect(presenter.select_options)
        .to contain_exactly ["first", admin_sets[0].id, {}],
                            ["second", admin_sets[1].id, {}],
                            ["third", admin_sets[2].id, {}]
    end
  end
end
