require 'spec_helper'

describe 'curation_concerns/file_sets/_browse_everything.html.erb', type: :view do
  let(:parent) { stub_model(GenericWork) }
  before do
    allow(view).to receive(:parent).and_return(parent)
  end
  it 'shows user timing warning' do
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_selector('div.alert-success', text: /Please note that if you upload a large number of files/i, count: 1)
  end
end
