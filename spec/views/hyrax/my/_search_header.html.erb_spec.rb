require 'spec_helper'

RSpec.describe 'hyrax/my/_search_header.html.erb', type: :view do
  before do
    stub_template 'hyrax/my/_did_you_mean.html.erb' => ''
    stub_template 'hyrax/my/_sort_and_per_page.html.erb' => ''
    stub_template 'hyrax/my/_facets.html.erb' => ''
    stub_template 'catalog/_search_form.html.erb' => ''
    stub_template 'hyrax/collections/_form_for_select_collection.html.erb' => ''
    view.extend BatchEditsHelper
    allow(view).to receive(:on_the_dashboard?).and_return(true)
    allow(view).to receive(:search_action_url).and_return('')
  end

  context "on my works page" do
    before do
      allow(view).to receive(:on_my_works?).and_return(true)
      render 'hyrax/my/search_header', current_tab: 'works'
    end
    it "has buttons" do
      expect(rendered).to have_selector('button', text: 'Add to Collection')
      expect(rendered).to have_selector('input[value="Edit Selected"]')
    end
  end

  context "not on my works page (i.e. Works shared with me)" do
    before do
      allow(view).to receive(:on_my_works?).and_return(false)
      render 'hyrax/my/search_header', current_tab: 'shared'
    end
    it "has buttons" do
      expect(rendered).not_to have_selector('button', text: 'Add to Collection')
      expect(rendered).to have_selector('input[value="Edit Selected"]')
    end
  end
end
