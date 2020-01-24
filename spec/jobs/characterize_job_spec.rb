RSpec.describe CharacterizeJob do
  context 'when the work is an ActiveFedora FileSet' do
    let(:file_set_id) { 'abc12345' }
    let(:filename)    { Rails.root.join('tmp', 'uploads', 'ab', 'c1', '23', '45', 'abc12345', 'picture.png').to_s }
    let(:file_set) do
      FileSet.new(id: file_set_id).tap do |fs|
        allow(fs).to receive(:original_file).and_return(file)
        allow(fs).to receive(:update_index)
      end
    end
    let(:file) do
      Hydra::PCDM::File.new.tap do |f|
        f.content = 'foo'
        f.original_name = 'picture.png'
        f.save!
        allow(f).to receive(:save!)
      end
    end

    context "when the file set's work is in a collection" do
      let(:work)       { build(:generic_work) }
      let(:collection) { build(:collection_lw) }

      before do
        allow(file_set).to receive(:parent).and_return(work)
        allow(work).to receive(:in_collections).and_return([collection])
      end
      it "reindexes the collection" do
        expect(collection).to receive(:update_index)
        described_class.perform_now(file_set)
      end
    end
  end
end
