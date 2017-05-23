RSpec.describe Hyrax::PagesController, type: :controller do
  let(:user) { FactoryGirl.create(:user) }

  before do
    sign_in user
  end

  context "when content exists" do
    describe "GET #show" do
      let(:page) { ContentBlock.create!(name: 'about_page', value: "foo bar") }

      it "updates the node and renders homepage layout" do
        get :show, params: { id: page.name }
        expect(response).to render_template('layouts/homepage')
        expect(response).to be_successful
        expect(assigns[:page]).to eq page
      end
    end
  end
  context "when content does not exist" do
    describe "GET #show" do
      it "creates the node" do
        get :show, params: { id: "about_page" }
        expect(response).to be_successful
        expect(assigns[:page]).not_to be_nil
      end
    end
  end
  context 'when editing pages' do
    let!(:about_page) do
      FactoryGirl.create(:content_block, name: 'about_page')
    end
    let!(:help_page) do
      FactoryGirl.create(:content_block, name: 'help_page')
    end
    context 'with an unprivileged user' do
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
        it "renders breadcrumbs and dashboard layout" do
          expect(controller).to receive(:add_breadcrumb).with('Home', root_path)
          expect(controller).to receive(:add_breadcrumb).with('Administration', dashboard_path)
          expect(controller).to receive(:add_breadcrumb).with('Configuration', '#')
          expect(controller).to receive(:add_breadcrumb).with('Pages', edit_pages_path)
          get :edit
          expect(response).to have_http_status(200)
          expect(response).to render_template('layouts/dashboard')
        end
      end

      describe "PATCH #update" do
        it "updates the about page" do
          patch :update, params: { id: about_page.id, content_block: { about_page: 'This is a new page about us!' } }
          expect(response).to redirect_to(edit_pages_path)
          expect(flash[:notice]).to include 'Pages updated'
          expect(ContentBlock.about_page.value).to eq "This is a new page about us!"
        end

        it "updates the help page" do
          patch :update, params: { id: help_page.id, content_block: { help_page: 'This page will provide more of the help you need.' } }
          expect(response).to redirect_to(edit_pages_path)
          expect(flash[:notice]).to include 'Pages updated'
          expect(ContentBlock.help_page.value).to eq 'This page will provide more of the help you need.'
        end
      end
    end
  end
end
