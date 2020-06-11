# frozen_string_literal: true
RSpec.describe 'hyrax/my/_search_header.html.erb', type: :view do
  before do
    stub_template 'hyrax/my/_did_you_mean.html.erb' => ''
    stub_template 'hyrax/my/_sort_and_per_page.html.erb' => ''
    stub_template 'hyrax/my/_facets.html.erb' => ''
    stub_template 'catalog/_search_form.html.erb' => ''
    stub_template 'hyrax/collections/_form_for_select_collection.html.erb' => ''
    view.extend Hyrax::BatchEditsHelper
    allow(view).to receive(:on_the_dashboard?).and_return(true)
    allow(view).to receive(:search_action_url).and_return('')
  end

  context "on my works page" do
    before do
      view.lookup_context.prefixes.push "hyrax/my/works"
      render 'hyrax/my/search_header', current_tab: 'works'
    end
    it "has buttons" do
      expect(rendered).to have_selector('input[value="Delete Selected"]')
      expect(rendered).to have_selector('button', text: 'Add to collection')
      expect(rendered).to have_selector('input[value="Edit Selected"]')
    end
  end

  context "on my collections page" do
    before do
      view.lookup_context.prefixes.push "hyrax/my/collections"
      render 'hyrax/my/search_header', current_tab: 'shared'
    end
    it "has buttons" do
      expect(rendered).to have_selector('button', text: 'Delete collections')
    end
  end
end
