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
end
