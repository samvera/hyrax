require 'spec_helper'

describe CurationConcerns::GenericWorksController do
  let(:user) { create(:user) }

  before { sign_in user }
  routes { Rails.application.routes }

  describe "#new" do
    it "is successful" do
      get :new
      expect(response).to be_successful
      expect(response).to render_template("layouts/sufia-one-column")
      expect(assigns[:curation_concern]).to be_kind_of GenericWork
      expect(subject.send(:show_presenter)).to be Sufia::WorkShowPresenter
    end
  end
end
