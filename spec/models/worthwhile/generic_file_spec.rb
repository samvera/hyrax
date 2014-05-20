require 'spec_helper'

describe Worthwhile::GenericFile do
  it "should have depositor" do
    subject.depositor = 'tess@example.com'
  end

  describe "to_solr" do
    before do
      subject.title = 'One Flew Over the Cuckoo\'s Nest'
    end
    let(:solr_doc) { subject.to_solr }

    it "has a solr_doc" do
      expect(solr_doc['desc_metadata__title_tesim']).to eq ['One Flew Over the Cuckoo\'s Nest']
      expect(solr_doc['desc_metadata__title_sim']).to eq ['One Flew Over the Cuckoo\'s Nest']
    end
  end
end
