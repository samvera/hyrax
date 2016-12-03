require 'spec_helper'

describe 'hyrax/permissions/confirm.html.erb', :no_clean, type: :view do
  let(:curation_concern) { stub_model(GenericWork) }

  before do
    allow(view).to receive(:curation_concern).and_return(curation_concern)
    render
  end

  let(:page) { Capybara::Node::Simple.new(rendered) }

  it 'renders the confirmation page' do
    expect(page).to have_content("Apply changes to contents?")
  end
end
