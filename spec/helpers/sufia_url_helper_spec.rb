describe SufiaUrlHelper do
  let(:document) { SolrDocument.new(id: 'foo123') }

  describe "#track_collection_path" do
    subject { helper.track_collection_path(document) }
    it { is_expected.to eq '/catalog/foo123/track' }
  end

  describe "#track_file_set_path" do
    subject { helper.track_file_set_path(document) }
    it { is_expected.to eq '/catalog/foo123/track' }
  end

  describe "#track_generic_work_path" do
    subject { helper.track_generic_work_path(document) }
    it { is_expected.to eq '/catalog/foo123/track' }
  end
end
