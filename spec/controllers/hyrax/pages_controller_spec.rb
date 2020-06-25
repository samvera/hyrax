RSpec.describe Hyrax::PagesController, type: :controller do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe "GET #show" do
    context "when content exists" do
      let!(:page) do
        ContentBlock.about_page = "foo bar"
        ContentBlock.for(:about)
      end

      it "updates the node and renders homepage layout" do
        get :show, params: { key: 'about' }
        expect(response).to render_template('layouts/homepage')
        expect(response).to be_successful
        expect(assigns[:page]).to eq page
      end
    end
    context "when content does not exist" do
      it "creates the node" do
        get :show, params: { key: 'about' }
        expect(response).to be_successful
        expect(assigns[:page]).not_to be_nil
      end
    end
    context "with an id that lacks a route" do
      it "raises an ActionController exception" do
        expect { get :show, params: { key: 'destroy_all' } }.to raise_error(ActionController::UrlGenerationError)
      end
    end
  end
  context 'when editing pages' do
    let!(:about_page) do
      create(:content_block, name: 'about_page')
    end
    let!(:help_page) do
      create(:content_block, name: 'help_page')
    end
    let!(:agreement_page) do
      create(:content_block, name: 'agreement_page')
    end
    let!(:terms_page) do
      create(:content_block, name: 'terms_page')
    end

    context 'with an unprivileged user' do
      describe "GET #edit" do
        it "denies the request" do
          get :edit, params: { id: ContentBlock.first.id }
          expect(response).to have_http_status(401)
        end
      end

      describe "PATCH #update" do
        it "denies the request" do
          patch :update, params: { id: ContentBlock.first.id }
          expect(response).to have_http_status(401)
        end
      end
    end

    context 'with an administrator' do
      let(:user) { create(:admin) }

      describe "GET #edit" do
        it "renders breadcrumbs and dashboard layout" do
          expect(controller).to receive(:add_breadcrumb).with('Home', root_path)
          expect(controller).to receive(:add_breadcrumb).with('Dashboard', dashboard_path)
          expect(controller).to receive(:add_breadcrumb).with('Configuration', '#')
          expect(controller).to receive(:add_breadcrumb).with('Pages', edit_pages_path)
          get :edit
          expect(response).to have_http_status(200)
          expect(response).to render_template('layouts/hyrax/dashboard')
        end
      end

      describe "PATCH #update" do
        it "updates the about page" do
          patch :update, params: { id: about_page.id, content_block: { about: 'This is a new page about us!' } }
          expect(response).to redirect_to("#{edit_pages_path}#about")
          expect(flash[:notice]).to include 'Pages updated'
          expect(ContentBlock.for(:about).value).to eq "This is a new page about us!"
        end

        it "updates the help page" do
          patch :update, params: { id: help_page.id, content_block: { help: 'This page will provide more of the help you need.' } }
          expect(response).to redirect_to("#{edit_pages_path}#help")
          expect(flash[:notice]).to include 'Pages updated'
          expect(ContentBlock.for(:help).value).to eq 'This page will provide more of the help you need.'
        end

        it "updates the agreement page" do
          patch :update, params: { id: agreement_page.id, content_block: { agreement: 'Here is the deposit agreement' } }
          expect(response).to redirect_to("#{edit_pages_path}#agreement")
          expect(flash[:notice]).to include 'Pages updated'
          expect(ContentBlock.for(:agreement).value).to eq 'Here is the deposit agreement'
        end

        it "updates the terms page" do
          patch :update, params: { id: terms_page.id, content_block: { terms: 'Terms of Use are good' } }
          expect(response).to redirect_to("#{edit_pages_path}#terms")
          expect(flash[:notice]).to include 'Pages updated'
          expect(ContentBlock.for(:terms).value).to eq 'Terms of Use are good'
        end
      end
    end
  end
end
