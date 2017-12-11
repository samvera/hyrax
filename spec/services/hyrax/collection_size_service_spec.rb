RSpec.describe Hyrax::CollectionSizeService do
  let(:coll1_attrs) do
    { id: 'col1', title_tesim: ['A Collection 1'], child_object_ids_ssim: works }
  end

  let(:coll1) { SolrDocument.new(coll1_attrs) }
  let(:solr) { Valkyrie::MetadataAdapter.find(:index_solr).connection }

  before do
    solr.add(coll1_attrs)
    solr.commit
  end

  describe "#run" do
    subject { described_class.run(coll1) }

    context "a collection with works" do
      let(:file1_attrs) { { id: 'file_1111', title_tesim: ['A first file set'], file_size_ssim: [50] } }
      let(:file2_attrs) { { id: 'file_2222', title_tesim: ['A second file set'], file_size_ssim: [55] } }

      let(:work1_attrs) { { id: 'work_1111', title_tesim: ['A first generic work'], file_set_ids_ssim: files1 } }
      let(:work2_attrs) { { id: 'work_2222', title_tesim: ['A second generic work'], file_set_ids_ssim: files2 } }

      let(:work1) { SolrDocument.new(work1_attrs) }
      let(:work2) { SolrDocument.new(work2_attrs) }
      let(:file1) { SolrDocument.new(file1_attrs) }
      let(:file2) { SolrDocument.new(file2_attrs) }

      let(:works) { [work1.id, work2.id] }

      before do
        solr.add(file1_attrs)
        solr.add(work1_attrs)
        solr.add(file2_attrs)
        solr.add(work2_attrs)
        solr.commit
      end

      context "that have files" do
        let(:files1) { [file1.id] }
        let(:files2) { [file2.id] }

        it "returns the correct size" do
          expect(subject).to eq(105.0)
        end
      end

      context "that do not have files" do
        let(:files1) { [] }
        let(:files2) { [] }

        specify "returns zero size" do
          expect(subject).to eq(0.0)
        end
      end

      context "that some have files" do
        let(:files1) { [file1.id] }
        let(:files2) { [] }

        specify "returns the correct size" do
          expect(subject).to eq(50.0)
        end
      end
    end

    context "a collection without works" do
      let(:works) { [] }

      specify "returns zero size" do
        expect(subject).to eq(0.0)
      end
    end
  end
end
