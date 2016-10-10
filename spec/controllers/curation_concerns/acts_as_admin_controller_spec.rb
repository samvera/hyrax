require 'spec_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    include CurationConcerns::ActAsAdminController

    def index
      render 'curation_concerns/admin/index'
    end
  end
  describe "layout" do
    it "renders admin" do
      get :index
      expect(response).to render_template "layouts/admin"
    end
  end

  describe "loads_configuration" do
    subject { controller.load_configuration }
    it { is_expected.to eq CurationConcerns::AdminController.configuration }
  end
end
