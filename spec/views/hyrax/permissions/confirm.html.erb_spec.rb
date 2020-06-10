# frozen_string_literal: true
RSpec.describe 'hyrax/permissions/confirm.html.erb', type: :view do
  let(:curation_concern) { stub_model(GenericWork) }
  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    allow(view).to receive(:curation_concern).and_return(curation_concern)
    # Stub visibility, or it will hit fedora
    allow(curation_concern).to receive(:visibility).and_return('open')
    render
  end

  it 'renders the confirmation page' do
    expect(page).to have_content("Apply changes to contents?")
  end
end
