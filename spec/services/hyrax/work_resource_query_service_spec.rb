# frozen_string_literal: true
module Hyrax
  RSpec.describe WorkResourceQueryService do
    let(:user) { create(:user) }
    let(:work) { FactoryBot.valkyrie_create(:monograph, title: ['Test work']) }
    let(:work_query_service) { described_class.new(id: work.id) }

    describe '#deleted_work?' do
      subject { work_query_service.deleted_work? }

      context 'when not in SOLR' do
        let(:work_query_service) { described_class.new(id: 'deleted-id') }

        it { is_expected.to be_truthy }
      end
      context 'when in SOLR' do
        it { is_expected.to be_falsey }
      end
    end
    describe '#work' do
      subject { work_query_service.work }

      context 'when in SOLR' do
        it { expect(subject.id).to eq(work.id) }
      end
    end
    describe '#to_s' do
      subject { work_query_service.to_s }

      context 'when the work is deleted' do
        let(:work_query_service) { described_class.new(id: 'deleted-id') }

        it { is_expected.to eq('work not found') }
      end

      context 'when the work is not deleted' do
        it 'will retrieve the SOLR document and use the #to_s method of that' do
          expect(subject).to eq(work.title.first)
        end
      end
    end
  end
end
