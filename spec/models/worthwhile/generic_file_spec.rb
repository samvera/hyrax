require 'spec_helper'

describe Worthwhile::GenericFile do
  it "should have depositor" do
    subject.depositor = 'tess@example.com'
  end

  describe "to_solr" do
    before do
      subject.title = 'One Flew Over the Cuckoo\'s Nest'
      subject.characterization.metadata.image.height = '500'
      subject.characterization.metadata.image.width = '600'
    end
    let(:solr_doc) { subject.to_solr }

    it "has a solr_doc" do
      expect(solr_doc['desc_metadata__title_tesim']).to eq ['One Flew Over the Cuckoo\'s Nest']
      expect(solr_doc['desc_metadata__title_sim']).to eq ['One Flew Over the Cuckoo\'s Nest']
      expect(solr_doc['height_isi']).to eq 500
      expect(solr_doc['width_isi']).to eq 600
    end
    
  end
end
