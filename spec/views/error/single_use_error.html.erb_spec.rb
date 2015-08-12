require 'spec_helper'

describe 'error/single_use_error.html.erb' do
  it 'renders without errors' do
    render file: 'error/single_use_error'
    expect(rendered).to have_text("Single Use Link Expired or Not Found")
  end
end
