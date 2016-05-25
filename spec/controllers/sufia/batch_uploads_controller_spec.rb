describe Sufia::BatchUploadsController do
  let(:user) { create(:user) }
  before do
    sign_in user
  end

  describe "#new" do
    it "is successful" do
      get :new
      expect(response).to be_successful
      expect(assigns[:form]).to be_kind_of Sufia::BatchUploadForm
    end
  end
  describe "#create" do
    context "enquing a update job" do
      it "is successful" do
        expect(BatchCreateJob).to receive(:perform_later)
          .with(user,
                { '1' => 'foo' },
                { '1' => 'Article' },
                ['1'],
                { keyword: [], visibility: 'open' },
                CurationConcerns::Operation)
        post :create, title: { '1' => 'foo' },
                      resource_type: { '1' => 'Article' },
                      uploaded_files: ['1'],
                      generic_work: { keyword: [""], visibility: 'open' }
        expect(response).to redirect_to Sufia::Engine.routes.url_helpers.dashboard_works_path
        expect(flash[:notice]).to include("Your files are being processed")
      end
    end

    describe "when submiting works on behalf of another user" do
      it "redirects to my shares page" do
        allow(BatchCreateJob).to receive(:perform_later)
        post :create,
             generic_work: {
               permissions_attributes: [
                 { type: "group", name: "public", access: "read" }
               ],
               on_behalf_of: 'elrayle'
             },
             uploaded_files: ['1']
        expect(response).to redirect_to Sufia::Engine.routes.url_helpers.dashboard_shares_path
      end
    end
  end

  describe "attributes_for_actor" do
    subject { controller.send(:attributes_for_actor) }
    before do
      controller.params = { title: { '1' => 'foo' },
                            uploaded_files: ['1'],
                            generic_work: { keyword: [""], visibility: 'open' } }
    end
    it "excludes uploaded_files and title" do
      expect(subject).to eq('keyword' => [],
                            'visibility' => 'open')
    end
  end
end
