require 'spec_helper'

describe Hydra::ModelMixins::SolrDocumentExtension do
  before do
    @doc = SolrDocument.new(:id=>'changeme:99')
  end

  it "should get_file_asset_count" do

    mock_result = {'response'=>{'numFound'=>0}}
    ActiveFedora::SolrService.should_receive(:query).with("is_part_of_t:\"changeme\\:99\"", :rows=>0, :raw=>true).and_return(mock_result)
    @doc.get_file_asset_count.should == 0
  end
end
