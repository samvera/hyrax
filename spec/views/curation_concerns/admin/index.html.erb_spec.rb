require 'spec_helper'

describe 'curation_concerns/admin/index.html.erb', type: :view do
  before do
    assign(:configuration, configuration)
    allow(view).to receive(:action_name).and_return(:index)
    stub_template 'curation_concerns/admin/_my_view_1.html.erb' => 'Mine 1'
    stub_template 'curation_concerns/admin/_my_view_2.html.erb' => 'Another One'
  end
  let(:configuration) do
    { actions: {
      index: {
        partials: [
          "my_view_1",
          "my_view_2"
        ]
      }
    } }
  end

  it "renders all the partials" do
    render
    expect(rendered).to have_content("Mine 1")
    expect(rendered).to have_content("Another One")
  end
end
