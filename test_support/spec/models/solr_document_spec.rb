require 'spec_helper'

describe SolrDocument do
  describe "#to_model" do
    # this isn't a great test, but...
    it "should try to cast the SolrDocument to the Fedora object" do
      ActiveFedora::Base.should_receive(:load_instance_from_solr).with('asdf', an_instance_of(SolrDocument))
      SolrDocument.new(:id => 'asdfg').to_model
    end
  end
end
