RSpec.describe Hyrax::TrophyPresenter do
  describe "find_by_user" do
    let(:user) { create(:user) }
    let(:work1) { create(:work, user: user) }
    let(:work2) { create(:work, user: user) }
    let(:work3) { create(:work, user: user) }
    let!(:trophy1) { user.trophies.create!(work_id: work1.id) }
    let!(:trophy2) { user.trophies.create!(work_id: work2.id) }
    let!(:trophy3) { user.trophies.create!(work_id: work3.id) }

    subject { described_class.find_by_user(user) }
    it "returns a list of generic works" do
      expect(subject.size).to eq 3
      expect(subject).to all(be_kind_of described_class)
    end
  end

  let(:presenter) { described_class.new(solr_document) }
  let(:solr_document) { SolrDocument.new(id: '123456', has_model_ssim: 'GenericWork', title_tesim: ['A Title']) }

  describe "id" do
    subject { presenter.id }
    it { is_expected.to eq '123456' }
  end

  describe "to_param" do
    subject { presenter.to_param }
    it { is_expected.to eq '123456' }
  end

  describe "model_name" do
    subject { presenter.model_name }
    it { is_expected.to eq GenericWork.model_name }
  end

  describe 'thumbnail_path' do
    let(:solr_document) { SolrDocument.new(thumbnail_path_ss: '/foo/bar.png') }
    subject { presenter.thumbnail_path }
    it { is_expected.to eq '/foo/bar.png' }
  end

  describe '#to_s' do
    subject { presenter.to_s }
    it { is_expected.to eq("A Title") }
  end
end
