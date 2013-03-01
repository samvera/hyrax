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
end
