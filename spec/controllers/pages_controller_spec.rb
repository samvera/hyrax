require 'spec_helper'

describe PagesController do
  describe "GET #show" do
    let(:page) { ContentBlock.create!(name: "about_page", value: "foo bar") }

    it "should update the node" do
      get :show, id: page.name
      expect(response).to be_successful
      expect(assigns[:page]).to eq page
    end
  end
end
