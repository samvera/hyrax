# frozen_string_literal: true

RSpec.describe Hyrax::TrophyPresenter do
  subject(:presenter) { described_class.new(solr_document) }

  let(:solr_document) do
    SolrDocument.new(id: '123456',
                     has_model_ssim: 'GenericWork',
                     title_tesim: ['A Title'],
                     thumbnail_path_ss: '/foo/bar.png')
  end

  its(:id) { is_expected.to eq '123456' }
  its(:model_name) { is_expected.to eq GenericWork.model_name }
  its(:thumbnail_path) { is_expected.to eq '/foo/bar.png' }
  its(:to_param) { is_expected.to eq '123456' }
  its(:to_s) { is_expected.to eq("A Title") }

  describe ".find_by_user" do
    let(:user)  { FactoryBot.create(:user) }
    let(:work1) { FactoryBot.create(:work, user: user) }
    let(:work2) { FactoryBot.create(:work, user: user) }
    let(:work3) { FactoryBot.create(:work, user: user) }

    before do
      user.trophies.create!(work_id: work1.id)
      user.trophies.create!(work_id: work2.id)
      user.trophies.create!(work_id: work3.id)
      user.trophies.create!(work_id: 'fake_id')
    end

    it "returns presenters for trophied works" do
      expect(described_class.find_by_user(user))
        .to contain_exactly(be_kind_of(described_class),
                            be_kind_of(described_class),
                            be_kind_of(described_class))
    end
  end
end
