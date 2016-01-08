require 'spec_helper'

describe Sufia::WorkShowPresenter do
  let(:solr_document) { SolrDocument.new(work.to_solr) }
  let(:presenter) { described_class.new(solr_document, ability) }

  describe '#itemtype' do
    let(:work) { build(:generic_work, resource_type: type) }
    let(:ability) { double "Ability" }

    subject { presenter.itemtype }

    context 'when resource_type is Audio' do
      let(:type) { ['Audio'] }

      it {
        is_expected.to eq 'http://schema.org/AudioObject'
      }
    end

    context 'when resource_type is Conference Proceeding' do
      let(:type) { ['Conference Proceeding'] }

      it { is_expected.to eq 'http://schema.org/ScholarlyArticle' }
    end
  end

  describe 'Featured Works for admin users' do
    let(:user) { create(:user) }
    before { allow(user).to receive_messages(groups: ['admin', 'registered']) }
    let(:ability) { Ability.new(user) }
    let!(:work) { build(:public_generic_work) }

    context 'on a brand new public work' do
      it 'allows user to feature the work' do
        allow(user).to receive(:can?).with(:create, FeaturedWork).and_return(true)
        expect(presenter.display_feature_link?).to be true
        expect(presenter.display_unfeature_link?).to be false
      end
    end

    context 'on an already featured work' do
      before do
        FeaturedWork.create(generic_work_id: work.id)
      end
      it 'allows user to unfeature the work' do
        expect(presenter.display_feature_link?).to be false
        expect(presenter.display_unfeature_link?).to be true
      end
    end
  end
end
