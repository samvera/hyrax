RSpec.describe 'hyrax/dashboard/collections/_form_branding.html.erb', type: :view do
  context 'displaying branding information for a collection' do
    let(:banner_info) { { file: "banner.gif", alttext: "Banner alt text" } }
    let(:logo_info) { [{ file: "logo.gif", alttext: "Logo alt text", linkurl: "http://abc.com" }] }

    before do
      assign(:banner_info, banner_info)
      assign(:logo_info, logo_info)
    end

    it "draws banner and logo information" do
      render
      expect(rendered).to include('banner.gif')
      expect(rendered).to include('Banner alt text')
      expect(rendered).to include('logo.gif')
      expect(rendered).to include('Logo alt text')
      expect(rendered).to include('http://abc.com')
    end
  end
end
