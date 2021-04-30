# frozen_string_literal: true

RSpec.describe Hyrax::PcdmMemberPresenterFactory, valkyrie_adapter: :test_adapter do
  subject(:factory) { described_class.new(solr_doc, ability) }
  let(:ability)     { :FAKE_ABILITY }
  let(:ids)         { [] }
  let(:solr_doc)    { SolrDocument.new(member_ids_ssim: ids) }

  shared_context 'with members' do
    let(:ids){ works.map(&:id) + file_sets.map(&:id) }

    let(:file_sets) do
      [FactoryBot.valkyrie_create(:hyrax_file_set),
       FactoryBot.valkyrie_create(:hyrax_file_set)]
    end

    let(:works) do
      [FactoryBot.valkyrie_create(:hyrax_work),
       FactoryBot.valkyrie_create(:hyrax_work)]
    end
  end

  describe '#file_set_presenters' do
    it 'is empty' do
      expect(factory.file_set_presenters).to be_empty
    end

    context 'with members' do
      include_context 'with members'

      it 'builds only file_set presenters' do
        require 'pry'; binding.pry
      end
    end
  end


  describe '#member_presenters' do
    it 'is empty' do
      expect(factory.member_presenters).to be_empty
    end

    it 'builds both file_set and work presenters'
  end

  describe '#work_presenters' do
    it 'is empty' do
      expect(factory.work_presenters).to be_empty
    end

    it 'builds only work presenters'
  end
end
