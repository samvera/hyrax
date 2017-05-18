RSpec.describe Hyrax::ContentBlocksController, type: :controller do
  let!(:announcement_text) do
    FactoryGirl.create(:content_block, name: 'announcement_text')
  end
  let!(:marketing_text) do
    FactoryGirl.create(:content_block, name: 'marketing_text')
  end
  let!(:featured_researcher) do
    FactoryGirl.create(:content_block, name: 'featured_researcher')
  end
  let!(:about_page) do
    FactoryGirl.create(:content_block, name: 'about_page')
  end
  let!(:help_page) do
    FactoryGirl.create(:content_block, name: 'help_page')
  end

  before do
    sign_in user
  end

  context 'with an unprivileged user' do
    let(:user) { FactoryGirl.create(:user) }

    describe "GET #edit" do
      it "denies the request" do
        get :edit
        expect(response).to have_http_status(401)
      end
    end

    describe "PATCH #update" do
      it "denies the request" do
        patch :update, params: { id: 1 }
        expect(response).to have_http_status(401)
      end
    end
  end

  context 'with an administrator' do
    let(:user) { FactoryGirl.create(:admin) }

    describe "GET #edit" do
      it "assigns the requested site as @site" do
        get :edit
        expect(response).to have_http_status(200)
      end
    end

    describe "PATCH #update" do
      it "updates the about page" do
        patch :update, params: { id: about_page.id, content_block: { about_page: 'This is a new page about us!' } }
        expect(response).to redirect_to(edit_content_blocks_path)
        expect(flash[:notice]).to include 'Content blocks updated'
        expect(ContentBlock.about_page.value).to eq "This is a new page about us!"
      end

      it "updates the help page" do
        patch :update, params: { id: help_page.id, content_block: { help_page: 'This page will provide more of the help you need.' } }
        expect(response).to redirect_to(edit_content_blocks_path)
        expect(flash[:notice]).to include 'Content blocks updated'
        expect(ContentBlock.help_page.value).to eq 'This page will provide more of the help you need.'
      end

      it "updates the announcement text" do
        patch :update, params: { id: announcement_text.id, content_block: { announcement_text: 'Now Hiring!' } }
        expect(response).to redirect_to(edit_content_blocks_path)
        expect(flash[:notice]).to include 'Content blocks updated'
        expect(ContentBlock.announcement_text.value).to eq "Now Hiring!"
      end

      it "updates the marketing text" do
        patch :update, params: { id: marketing_text.id, content_block: { marketing_text: '99 days since last crash!' } }
        expect(response).to redirect_to(edit_content_blocks_path)
        expect(flash[:notice]).to include 'Content blocks updated'
        expect(ContentBlock.marketing_text.value).to eq "99 days since last crash!"
      end

      it "updates the featured researcher" do
        patch :update, params: { id: featured_researcher.id, content_block: { featured_researcher: 'Jane Doe is unimpeachable' } }
        expect(response).to redirect_to(edit_content_blocks_path)
        expect(flash[:notice]).to include 'Content blocks updated'
        expect(ContentBlock.featured_researcher.value).to eq "Jane Doe is unimpeachable"
      end
    end
  end
end
