require 'spec_helper'

describe SufiaUrlHelper do
  let(:document) { SolrDocument.new(id: 'foo123') }

  describe "#track_collection_path" do
    subject { helper.track_collection_path(document) }
    it { is_expected.to eq '/catalog/foo123/track' }
  end

  describe "#track_generic_file_path" do
    subject { helper.track_generic_file_path(document) }
    it { is_expected.to eq '/catalog/foo123/track' }
  end
end
