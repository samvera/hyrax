describe Sufia::PagesController, type: :controller do
  let(:page_name) { "about_page" }
  context "content exists" do
    describe "GET #show" do
      let(:page) { ContentBlock.create!(name: page_name, value: "foo bar") }

      it "updates the node" do
        get :show, params: { id: page.name }
        expect(response).to be_successful
        expect(assigns[:page]).to eq page
      end
    end
  end
  context "content does not exist" do
    describe "GET #show" do
      it "creates the node" do
        get :show, params: { id: "about_page" }
        expect(response).to be_successful
        expect(assigns[:page]).not_to be_nil
      end
    end
  end
end
