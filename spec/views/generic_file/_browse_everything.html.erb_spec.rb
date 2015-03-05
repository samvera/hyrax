require 'spec_helper'

describe 'generic_files/_browse_everything.html.erb', :type => :view do
  it 'shows user timing warning' do
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_selector('div.alert-success', text: /Please note that if you upload a large number of files/i , count: 1)
  end
end
