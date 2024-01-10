# frozen_string_literal: true
module Hyrax
  RSpec.describe WorkQueryService, :active_fedora do
    let(:user) { create(:user) }
    let(:work_id) { 'abc' }
    let(:work_relation) { double('Work Relation') }
    let(:work_query_service) { described_class.new(id: work_id, work_relation: work_relation) }

    describe '#default_work_relation' do
      subject { work_query_service.send(:default_work_relation) }

      it { is_expected.to respond_to(:find).with(1).arguments }
      it { is_expected.to respond_to(:exists?).with(1).arguments }
    end

    describe '#deleted_work?' do
      subject { work_query_service.deleted_work? }

      context 'when not in SOLR' do
        before { allow(work_relation).to receive(:exists?).with(work_id).and_return(false) }
        it { is_expected.to be_truthy }
      end
      context 'when in SOLR' do
        before { allow(work_relation).to receive(:exists?).with(work_id).and_return(true) }
        it { is_expected.to be_falsey }
      end
    end
    describe '#work' do
      let(:expected_work) { double('Work') }

      subject { work_query_service.work }

      context 'when in SOLR' do
        before { allow(work_relation).to receive(:find).with(work_id).and_return(expected_work) }
        it { is_expected.to eq(expected_work) }
      end
    end
    describe '#to_s' do
      subject { work_query_service.to_s }

      context 'when the work is deleted' do
        before { allow(work_relation).to receive(:exists?).with(work_id).and_return(false) }
        it { is_expected.to eq('work not found') }
      end

      context 'when the work is not deleted' do
        # NOTE: This is testing the full behavior of finding
        let!(:work_query_service) { described_class.new(id: work.id) }
        let!(:work) { create(:generic_work, title: ["Test work"]) }

        it 'will retrieve the SOLR document and use the #to_s method of that' do
          expect(subject).to eq(work.title.first)
        end
      end
    end
  end
end
