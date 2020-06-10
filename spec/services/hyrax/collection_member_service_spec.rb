# frozen_string_literal: true
RSpec.describe Hyrax::CollectionMemberService, :clean_repo do
  let(:user) { create(:user, groups: 'potato') }
  let!(:ability) { ::Ability.new(user) }
  let!(:col1) { build(:collection_lw, id: 'col1', user: user, with_solr_document: true) }
  let!(:col2) { build(:collection_lw, id: 'col2', with_solr_document: true) }
  let(:colls) { [col1.id, col2.id] }
  let(:work_attrs) { { id: '123', title_tesim: ['A generic work'], member_of_collection_ids_ssim: colls } }
  let(:work) { SolrDocument.new(work_attrs) }

  describe "#run" do
    subject { described_class.run(work, ability) }

    it "returns only authorized parent collections" do
      expect(subject.count).to eq(1)
      ids = subject.map { |col| col[:id] }
      expect(ids).to contain_exactly(col1.id)
    end
  end
end
