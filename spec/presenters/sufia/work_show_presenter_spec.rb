describe Sufia::WorkShowPresenter do
  let(:solr_document) { SolrDocument.new(work.to_solr) }
  let(:presenter) { described_class.new(solr_document, ability) }

  subject { described_class.new(double, double) }
  it { is_expected.to delegate_method(:based_near).to(:solr_document) }
  it { is_expected.to delegate_method(:related_url).to(:solr_document) }
  it { is_expected.to delegate_method(:depositor).to(:solr_document) }
  it { is_expected.to delegate_method(:identifier).to(:solr_document) }
  it { is_expected.to delegate_method(:resource_type).to(:solr_document) }
  it { is_expected.to delegate_method(:keyword).to(:solr_document) }
  it { is_expected.to delegate_method(:itemtype).to(:solr_document) }

  describe 'stats_path' do
    let(:user) { 'sarah' }
    let(:ability) { double "Ability" }
    let(:work) { build(:generic_work, id: '123abc') }
    it { expect(presenter.stats_path).to eq Sufia::Engine.routes.url_helpers.stats_work_path(id: work) }
  end

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

  describe 'admin users' do
    let(:user)    { create(:user) }
    let(:ability) { Ability.new(user) }
    let!(:work)   { build(:public_generic_work) }

    before { allow(user).to receive_messages(groups: ['admin', 'registered']) }

    context 'with a new public work' do
      it 'can feature the work' do
        allow(user).to receive(:can?).with(:create, FeaturedWork).and_return(true)
        expect(presenter.display_feature_link?).to be true
        expect(presenter.display_unfeature_link?).to be false
      end
    end

    context 'with a featured work' do
      before { FeaturedWork.create(work_id: work.id) }
      it 'can unfeature the work' do
        expect(presenter.display_feature_link?).to be false
        expect(presenter.display_unfeature_link?).to be true
      end
    end

    describe "#editor?" do
      subject { presenter.editor? }
      it { is_expected.to be true }
    end
  end

  describe "#member_presenters" do
    let(:work) { create(:work_with_one_file) }
    let(:ability) { double "Ability" }

    it "returns appropriate classes for each" do
      expect(presenter.member_presenters.size).to eq 1
      expect(presenter.member_presenters.first).to be_instance_of(::Sufia::FileSetPresenter)
    end
  end
end
