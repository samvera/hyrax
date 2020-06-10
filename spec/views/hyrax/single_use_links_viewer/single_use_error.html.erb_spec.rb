# frozen_string_literal: true
RSpec.describe 'hyrax/single_use_links_viewer/single_use_error.html.erb' do
  it 'renders without errors' do
    render
    expect(rendered).to have_text("Single Use Link Expired or Not Found")
  end
end
