describe Sufia::CollectionMemberService do
  let(:work_attrs) { { id: '123', title_tesim: ['A generic work'] } }

  let(:coll1_attrs) { { id: 'col1', title_tesim: ['A Collection 1'], child_object_ids_ssim: [work.id] } }
  let(:coll2_attrs) { { id: 'col2', title_tesim: ['A Collection 2'], child_object_ids_ssim: [work.id, 'abc123'] } }
  let(:coll3_attrs) { { id: 'col3', title_tesim: ['A Collection 3'], child_object_ids_ssim: ['abc123'] } }

  let(:work) { SolrDocument.new(work_attrs) }

  before do
    ActiveFedora::SolrService.add(coll1_attrs)
    ActiveFedora::SolrService.add(coll2_attrs)
    ActiveFedora::SolrService.add(coll3_attrs)
    ActiveFedora::SolrService.commit
  end

  describe "#run" do
    subject { described_class.run(work) }

    specify "should return correct collections" do
      expect(subject.length).to eq(2)
      ids = subject.map { |col| col[:id] }
      expect(ids).to include(coll1_attrs[:id])
      expect(ids).to include(coll2_attrs[:id])
      expect(ids).not_to include(coll3_attrs[:id])
    end
  end
end
