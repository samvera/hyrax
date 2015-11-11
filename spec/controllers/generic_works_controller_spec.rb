require 'spec_helper'

describe GenericWorksController do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "#new" do
    it "is successful" do
      get :new
      expect(response).to be_successful
      expect(response).to render_template("layouts/sufia-one-column")
      expect(assigns[:curation_concern]).to be_kind_of GenericWork
    end
  end
end
