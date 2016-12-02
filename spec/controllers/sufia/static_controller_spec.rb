describe Sufia::StaticController, type: :controller do
  routes { Sufia::Engine.routes }
  describe "#mendeley" do
    it "renders page" do
      get "mendeley"
      expect(response).to be_success
      expect(response).to render_template "layouts/homepage"
    end
    it "renders no layout with javascript" do
      get :mendeley, xhr: true
      expect(response).to be_success
      expect(response).not_to render_template "layouts/homepage"
    end
  end

  describe "#zotero" do
    it "renders page" do
      get "zotero"
      expect(response).to be_success
      expect(response).to render_template "layouts/homepage"
    end
    it "renders no layout with javascript" do
      get :zotero, xhr: true
      expect(response).to be_success
      expect(response).not_to render_template "layouts/homepage"
    end
  end
end
