describe Sufia::BatchUploadsController do
  let(:user) { create(:user) }
  before do
    sign_in user
  end

  describe "#new" do
    it "is successful" do
      get :new
      expect(response).to be_successful
      expect(assigns[:form]).to be_kind_of Sufia::Forms::BatchUploadForm
    end
  end

  describe "#create" do
    context "enquing a update job" do
      let(:expected_types) do
        { '1' => 'Article' }
      end
      let(:expected_individual_params) do
        { '1' => 'foo' }
      end
      let(:expected_shared_params) do
        { 'keyword' => [], 'visibility' => 'open' }
      end

      it "is successful" do
        expect(BatchCreateJob).to receive(:perform_later)
          .with(user,
                expected_individual_params,
                expected_types,
                ['1'],
                expected_shared_params,
                CurationConcerns::Operation)
        post :create, params: {
          title: { '1' => 'foo' },
          resource_type: { '1' => 'Article' },
          uploaded_files: ['1'],
          batch_upload_item: { keyword: [""], visibility: 'open' }
        }
        expect(response).to redirect_to Sufia::Engine.routes.url_helpers.dashboard_works_path
        expect(flash[:notice]).to include("Your files are being processed")
      end
    end

    describe "when submiting works on behalf of another user" do
      it "redirects to my shares page" do
        allow(BatchCreateJob).to receive(:perform_later)
        post :create, params: {
          batch_upload_item: {
            permissions_attributes: [
              { type: "group", name: "public", access: "read" }
            ],
            on_behalf_of: 'elrayle'
          },
          title: { '1' => 'foo' },
          resource_type: { '1' => 'Article' },
          uploaded_files: ['1']
        }
        expect(response).to redirect_to Sufia::Engine.routes.url_helpers.dashboard_shares_path
      end
    end
  end

  describe "attributes_for_actor" do
    subject { controller.send(:attributes_for_actor) }
    before do
      controller.params = { title: { '1' => 'foo' },
                            uploaded_files: ['1'],
                            batch_upload_item: { keyword: [""], visibility: 'open' } }
    end
    let(:expected_shared_params) do
      if Rails.version < '5.0.0'
        { 'keyword' => [], 'visibility' => 'open' }
      else
        ActionController::Parameters.new(keyword: [], visibility: 'open').permit!
      end
    end
    it "excludes uploaded_files and title" do
      expect(subject).to eq expected_shared_params
    end
  end
end
