require 'spec_helper'

RSpec.describe 'hyrax/my/_sort_and_per_page.html.erb', type: :view do
  let(:mock_response) { double(response: { 'numFound' => 7 }) }
  let(:sort_fields) { double(empty?: true) }

  before do
    stub_template 'hyrax/collections/_form_for_select_collection.html.erb' => ''
    @response = mock_response
    view.extend BatchEditsHelper
    allow(view).to receive(:sort_fields).and_return(sort_fields)
  end

  context "on my works page" do
    before do
      allow(view).to receive(:on_my_works?).and_return(true)
      render
    end
    it "has buttons" do
      expect(rendered).to have_selector('button', text: 'Add to Collection')
      expect(rendered).to have_selector('input[value="Edit Selected"]')
    end
  end

  context "not on my works page (i.e. Works shared with me)" do
    before do
      allow(view).to receive(:on_my_works?).and_return(false)
      render
    end
    it "has buttons" do
      expect(rendered).not_to have_selector('button', text: 'Add to Collection')
      expect(rendered).to have_selector('input[value="Edit Selected"]')
    end
  end
end
