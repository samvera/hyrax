require 'spec_helper'

describe "dashboard/_index_partials/_thumbnail_display.html.erb" do
  describe "for an audio object" do
    before do
      allow(view).to receive(:document).and_return(stub_model(GenericFile, mime_type: 'audio/wav', noid: '123'))
    end
    it "should show the audio thumbnail" do
      render
      rendered.should match /src="\/assets\/audio.png"/
    end
  end
  describe "for an document object" do
    before do
      allow(view).to receive(:document).and_return(stub_model(GenericFile, mime_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', noid: '123'))
    end
    it "should show the default thumbnail" do
      render
      rendered.should match /src="\/assets\/default.png"/
    end
  end
end
