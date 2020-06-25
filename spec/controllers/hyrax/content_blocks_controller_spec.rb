RSpec.describe Hyrax::ContentBlocksController, type: :controller do
  let!(:announcement_text) do
    create(:content_block, name: 'announcement_text')
  end
  let!(:marketing_text) do
    create(:content_block, name: 'marketing_text')
  end
  let!(:featured_researcher) do
    create(:content_block, name: 'featured_researcher')
  end

  before do
    sign_in user
  end

  context 'with an unprivileged user' do
    let(:user) { create(:user) }

    describe "GET #edit" do
      it "denies the request" do
        get :edit
        expect(response).to have_http_status(401)
      end
    end

    describe "PATCH #update" do
      it "denies the request" do
        patch :update, params: { id: ContentBlock.first.to_param }
        expect(response).to have_http_status(401)
      end
    end
  end

  context 'with an administrator' do
    let(:user) { create(:admin) }

    describe "GET #edit" do
      it "renders breadcrumbs" do
        expect(controller).to receive(:add_breadcrumb).with('Home', root_path)
        expect(controller).to receive(:add_breadcrumb).with('Dashboard', dashboard_path)
        expect(controller).to receive(:add_breadcrumb).with('Configuration', '#')
        expect(controller).to receive(:add_breadcrumb).with('Content Blocks', edit_content_blocks_path)
        get :edit
        expect(response).to have_http_status(200)
      end
    end

    describe "PATCH #update" do
      it "updates the announcement text" do
        patch :update, params: { id: announcement_text.id, content_block: { announcement: 'Now Hiring!' } }
        expect(response).to redirect_to(edit_content_blocks_path)
        expect(flash[:notice]).to include 'Content blocks updated'
        expect(ContentBlock.announcement_text.value).to eq "Now Hiring!"
      end

      it "updates the marketing text" do
        patch :update, params: { id: marketing_text.id, content_block: { marketing: '99 days since last crash!' } }
        expect(response).to redirect_to(edit_content_blocks_path)
        expect(flash[:notice]).to include 'Content blocks updated'
        expect(ContentBlock.marketing_text.value).to eq "99 days since last crash!"
      end

      it "updates the featured researcher" do
        patch :update, params: { id: featured_researcher.id, content_block: { researcher: 'Jane Doe is unimpeachable' } }
        expect(response).to redirect_to(edit_content_blocks_path)
        expect(flash[:notice]).to include 'Content blocks updated'
        expect(ContentBlock.featured_researcher.value).to eq "Jane Doe is unimpeachable"
      end
    end
  end
end
