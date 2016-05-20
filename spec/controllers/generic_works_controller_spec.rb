require 'spec_helper'

describe CurationConcerns::GenericWorksController do
  let(:user) { create(:user) }

  before { sign_in user }
  routes { Rails.application.routes }

  describe "#new" do
    before { get :new }
    it "is successful" do
      expect(response).to be_successful
      expect(response).to render_template("layouts/sufia-one-column")
      expect(assigns[:curation_concern]).to be_kind_of GenericWork
    end

    it "applies depositor metadata" do
      expect(assigns[:form].depositor).to eq user.user_key
      expect(assigns[:curation_concern].depositor).to eq user.user_key
    end
  end

  describe "#edit" do
    let(:work) { create(:work, title: ['test title'], user: user) }

    it "is successful" do
      get :edit, id: work
      expect(response).to be_successful
      expect(response).to render_template("layouts/sufia-one-column")
      expect(assigns[:form]).to be_kind_of CurationConcerns::GenericWorkForm
    end

    context "without a referer" do
      it "sets breadcrumbs" do
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
        get :edit, id: work
        expect(response).to be_successful
      end
    end

    context "with a referer" do
      before do
        allow(controller.request).to receive(:referer).and_return('foo')
      end

      it "sets breadcrumbs" do
        expect(controller).to receive(:add_breadcrumb).with('My Dashboard', Sufia::Engine.routes.url_helpers.dashboard_index_path)
        expect(controller).to receive(:add_breadcrumb).with('My Works', Sufia::Engine.routes.url_helpers.dashboard_works_path)
        expect(controller).to receive(:add_breadcrumb).with(I18n.t("sufia.work.browse_view"), Rails.application.routes.url_helpers.curation_concerns_generic_work_path(work))
        get :edit, id: work
        expect(response).to be_successful
      end
    end
  end

  describe "#show" do
    let(:work) do
      create(:work, title: ['test title'], user: user)
    end

    it "is successful" do
      get :show, id: work
      expect(response).to be_successful
      expect(assigns(:presenter)).to be_kind_of Sufia::WorkShowPresenter
    end

    it 'renders an endnote file' do
      get :show, id: work, format: 'endnote'
      expect(response).to be_successful
    end

    context "without a referer" do
      it "sets breadcrumbs" do
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
        get :show, id: work
        expect(response).to be_successful
      end
    end

    context "with a referer" do
      before do
        allow(controller.request).to receive(:referer).and_return('foo')
      end

      it "sets breadcrumbs" do
        expect(controller).to receive(:add_breadcrumb).with('My Dashboard', Sufia::Engine.routes.url_helpers.dashboard_index_path)
        expect(controller).to receive(:add_breadcrumb).with('My Works', Sufia::Engine.routes.url_helpers.dashboard_works_path)
        expect(controller).to receive(:add_breadcrumb).with('test title', Sufia::Engine.routes.url_helpers.curation_concerns_generic_work_path(work.id))
        get :show, id: work
        expect(response).to be_successful
      end
    end
  end

  describe "#create" do
    let(:actor) { double('An actor') }
    let(:work) { create(:work) }
    before do
      allow(controller).to receive(:actor)
        .and_return(actor)

      # Stub out the creation of the work so we can redirect somewhere
      allow(controller).to receive(:curation_concern).and_return(work)
    end

    it "attaches files" do
      expect(actor).to receive(:create)
        .with(hash_including(:uploaded_files))
        .and_return(true)
      post :create, generic_work: { title: ["First title"],
                                    visibility: 'open' },
                    uploaded_files: ['777', '888']
      expect(flash[:notice]).to eq "Your files are being processed by Sufia in the background. The metadata and access controls you specified are being applied. Files will be marked <span class=\"label label-danger\" title=\"Private\">Private</span> until this process is complete (shouldn't take too long, hang in there!). You may need to refresh your dashboard to see these updates."
      expect(response).to redirect_to main_app.curation_concerns_generic_work_path(work)
    end

    context "from browse everything" do
      let(:url1) { "https://dl.dropbox.com/fake/blah-blah.filepicker-demo.txt.txt" }
      let(:url2) { "https://dl.dropbox.com/fake/blah-blah.Getting%20Started.pdf" }
      let(:browse_everything_params) do
        { "0" => { "url" => url1,
                   "expires" => "2014-03-31T20:37:36.214Z",
                   "file_name" => "filepicker-demo.txt.txt" },
          "1" => { "url" => url2,
                   "expires" => "2014-03-31T20:37:36.731Z",
                   "file_name" => "Getting+Started.pdf" } }.with_indifferent_access
      end
      let(:uploaded_files) do
        browse_everything_params.values.map { |v| v['url'] }
      end

      context "For a batch upload" do
        # TODO: move this to batch_uploads controller
        it "ingests files from provide URLs" do
          skip "Creating a FileSet without a parent work is not yet supported"
          expect(ImportUrlJob).to receive(:perform_later).twice
          expect { post :create, selected_files: browse_everything_params,
                                 file_set: {}
          }.to change(FileSet, :count).by(2)
          created_files = FileSet.all
          ["https://dl.dropbox.com/fake/blah-blah.Getting%20Started.pdf", "https://dl.dropbox.com/fake/blah-blah.filepicker-demo.txt.txt"].each do |url|
            expect(created_files.map(&:import_url)).to include(url)
          end
          ["filepicker-demo.txt.txt", "Getting+Started.pdf"].each do |filename|
            expect(created_files.map(&:label)).to include(filename)
          end
        end
      end

      context "when a work id is passed" do
        let(:work) do
          GenericWork.create!(title: ['test title']) do |w|
            w.apply_depositor_metadata(user)
          end
        end
        it "records the work" do
          # TODO: ensure the actor stack, called with these params
          # makes one work, two file sets and calls ImportUrlJob twice.
          expect(actor).to receive(:create)
            .with(hash_including(uploaded_files: [],
                                 remote_files: browse_everything_params.values))
            .and_return(true)
          post :create, selected_files: browse_everything_params,
                        uploaded_files: uploaded_files,
                        parent_id: work.id,
                        generic_work: { title: ['First title'] }
          expect(flash[:notice]).to eq "Your files are being processed by Sufia in the background. The metadata and access controls you specified are being applied. Files will be marked <span class=\"label label-danger\" title=\"Private\">Private</span> until this process is complete (shouldn't take too long, hang in there!). You may need to refresh your dashboard to see these updates."
          expect(response).to redirect_to main_app.curation_concerns_generic_work_path(work)
        end
      end
    end
  end
end
