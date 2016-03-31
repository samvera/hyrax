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
    let(:work) { create(:work, user: user) }

    it "is successful" do
      get :edit, id: work
      expect(response).to be_successful
      expect(response).to render_template("layouts/sufia-one-column")
      expect(assigns[:form]).to be_kind_of CurationConcerns::GenericWorkForm
    end
  end

  describe "#show" do
    let(:work) { create(:work, user: user) }

    it "is successful" do
      get :show, id: work
      expect(response).to be_successful
      expect(assigns(:presenter)).to be_kind_of Sufia::WorkShowPresenter
    end
    it 'renders an endnote file' do
      get :show, id: work, format: 'endnote'
      expect(response).to be_successful
    end
  end

  describe "#create" do
    let(:actor) { double('An actor') }
    let(:work) { create(:work) }
    before do
      allow(Sufia::CreateWithFilesActor).to receive(:new)
        .with(CurationConcerns::GenericWorkActor, ['777', '888'])
        .and_return(actor)

      # Stub out the creation of the work so we can redirect somewhere
      allow(controller).to receive(:curation_concern).and_return(work)
    end

    it "attaches files" do
      expect(actor).to receive(:create).and_return(true)
      post :create, generic_work: { title: ["First title"],
                                    visibility: 'open' },
                    uploaded_files: ['777', '888']
      expect(flash[:notice]).to eq "Your files are being processed by Repository in the background. The metadata and access controls you specified are being applied. Files will be marked <span class=\"label label-danger\" title=\"Private\">Private</span> until this process is complete (shouldn't take too long, hang in there!). You may need to refresh your dashboard to see these updates."
      expect(response).to redirect_to main_app.curation_concerns_generic_work_path(work)
    end
  end
end
