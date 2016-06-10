require 'spec_helper'

describe 'curation_concerns/permissions/confirm.html.erb', :no_clean do
  let(:curation_concern) { stub_model(GenericWork) }

  before do
    allow(view).to receive(:curation_concern).and_return(curation_concern)
  end

  it 'renders the confirmation page' do
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_content("Apply changes to contents?")
  end
end
