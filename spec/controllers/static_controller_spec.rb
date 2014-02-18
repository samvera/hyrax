require 'spec_helper'

describe StaticController do
  routes { Sufia::Engine.routes }
  describe "#mendeley" do
    it "renders page" do
      get "mendeley"
      response.should be_success
      response.should render_template "layouts/homepage"
    end
    it "renders no layout with javascript" do
      get "mendeley" ,{format:"js"}
      response.should be_success
      response.should_not render_template "layouts/homepage"
    end
  end

  describe "#zotero" do
    it "renders page" do
      get "zotero"
      response.should be_success
      response.should render_template "layouts/homepage"
    end
    it "renders no layout with javascript" do
      get "zotero" ,{format:"js"}
      response.should be_success
      response.should_not render_template "layouts/homepage"
    end
  end
end
