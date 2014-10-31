require 'spec_helper'

describe 'collections/_show_descriptions.html.erb', :type => :view do
  context 'displaying a custom collection' do
    before do
      @collection = mock_model(Collection)
      allow(view).to receive(:blacklight_config).and_return(Blacklight::Configuration.new)
      allow(@collection).to receive(:date_modified).and_return(["today"])
      allow(@collection).to receive(:terms_for_display).and_return([:date_modified])
      allow(@collection).to receive(:members).and_return(["foo","bar"])
      allow(@collection).to receive(:bytes).and_return(123456678)
    end

    it "should draw the metadata fields for collection" do
      render
      expect(rendered).to have_content 'Date modified'
      expect(rendered).to include('itemprop="date_modified"')
      expect(rendered).to have_content 'Total Items'
      expect(rendered).to have_content '2'
      expect(rendered).to have_content 'Size'
      expect(rendered).to have_content '118 MB'
    end
  end

end
