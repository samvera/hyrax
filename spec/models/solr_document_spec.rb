require 'spec_helper'

describe SolrDocument do
  describe "when mime-type is 'application/mxf'" do
    before do
      subject['mime_type_tesim'] = ['application/mxf']
    end
    it "should be a video" do
      subject.should be_video
    end
  end

  describe "date_uploaded" do
    before do
      subject['desc_metadata__date_uploaded_dtsi'] = '2013-03-14T00:00:00Z'
    end
    it "should be a date" do
      subject.date_uploaded.should == '03/14/2013'
    end
  end
end
