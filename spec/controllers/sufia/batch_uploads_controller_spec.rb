describe Sufia::BatchUploadsController do
  let(:user) { create(:user) }
  let(:expected_types) do
    { '1' => 'Article',
      '2' => ['Article', 'Text'] }
  end
  let(:expected_individual_params) do
    { '1' => 'foo',
      '2' => 'bar' }
  end
  let(:expected_shared_params) do
    { 'keyword' => [], 'visibility' => 'open', :model => 'GenericWork' }
  end
  let(:batch_upload_item) do
    { keyword: [""], visibility: 'open', payload_concern: 'GenericWork' }
  end
  let(:post_params) do
    {
      title: expected_individual_params,
      resource_type: expected_types,
      uploaded_files: ['1', '2'],
      batch_upload_item: batch_upload_item
    }
  end

  before do
    # allow(user).to receive(:can?).with(:create, GenericWork).and_return(true)
    # allow(user).to receive(:can?).with(:create, Atlas).and_return(true)
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
    context "with expected params" do
      it "is successful" do
        expect(BatchCreateJob).to receive(:perform_later)
          .with(user,
                expected_individual_params,
                expected_types,
                ['1', '2'],
                expected_shared_params,
                a_kind_of(Sufia::BatchCreateOperation))
        post :create, params: post_params
        expect(response).to redirect_to Sufia::Engine.routes.url_helpers.dashboard_works_path
        expect(flash[:notice]).to include("Your files are being processed")
      end
    end

    context 'with missing resource_type' do
      let(:post_params) do
        {
          title: expected_individual_params,
          uploaded_files: ['1', '2'],
          batch_upload_item: batch_upload_item
        }
      end
      it 'is successful' do
        expect(BatchCreateJob).to receive(:perform_later)
          .with(user,
                expected_individual_params,
                {},
                ['1', '2'],
                expected_shared_params,
                a_kind_of(Sufia::BatchCreateOperation))
        post :create, params: post_params
        expect(response).to redirect_to Sufia::Engine.routes.url_helpers.dashboard_works_path
        expect(flash[:notice]).to include("Your files are being processed")
      end
    end

    context "when submiting works on behalf of another user" do
      let(:batch_upload_item) do
        {
          payload_concern: Atlas,
          permissions_attributes: [
            { type: "group", name: "public", access: "read" }
          ],
          on_behalf_of: 'elrayle'
        }
      end
      it "redirects to my shares page" do
        allow(BatchCreateJob).to receive(:perform_later)
        post :create, params: post_params
        expect(response).to redirect_to Sufia::Engine.routes.url_helpers.dashboard_shares_path
      end
    end
  end

  describe "attributes_for_actor" do
    subject { controller.send(:attributes_for_actor) }
    before do
      controller.params = post_params
    end
    let(:expected_shared_params) do
      if Rails.version < '5.0.0'
        { 'keyword' => [], 'visibility' => 'open' }
      else
        ActionController::Parameters.new(keyword: [], visibility: 'open').permit!
      end
    end
    it "excludes uploaded_files and title" do
      expect(subject).not_to include('title', :title, 'uploaded_files', :uploaded_files)
      expect(subject).to eq expected_shared_params
    end
  end
end
