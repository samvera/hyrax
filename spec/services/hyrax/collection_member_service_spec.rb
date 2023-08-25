# frozen_string_literal: true
RSpec.describe Hyrax::CollectionMemberService, :clean_repo do
  let(:user) { FactoryBot.create(:user, groups: 'potato') }
  let(:ability) { ::Ability.new(user) }
  let(:col1) { FactoryBot.valkyrie_create(:hyrax_collection, user: user, with_index: true) }
  let(:col2) { FactoryBot.valkyrie_create(:hyrax_collection, with_index: true) }
  let(:colls) { [col1.id, col2.id] }
  let(:work_attrs) { { id: '123', title_tesim: ['A generic work'], member_of_collection_ids_ssim: colls } }
  let(:work_doc) { SolrDocument.new(work_attrs) }

  describe "#run" do
    it "returns only authorized parent collections" do
      expect(described_class.run(work_doc, ability))
        .to contain_exactly(have_attributes(id: col1.id))
    end
  end
end
