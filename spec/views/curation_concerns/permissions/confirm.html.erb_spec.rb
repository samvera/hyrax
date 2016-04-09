require 'spec_helper'

describe 'curation_concerns/permissions/confirm.html.erb', :no_clean do
  class MockCurationConcern
    attr_reader :human_readable_type, :visibility
    def initialize
      @human_readable_type = "GenericWork"
      @visibility = "public"
    end
  end

  let!(:curation_concern) { MockCurationConcern.new }
  before do
    allow(view).to receive(:curation_concern).and_return(curation_concern)
  end

  it 'renders the confirmation page' do
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_content("Apply changes to contents?")
  end
end
