require 'spec_helper'

describe 'hyrax/base/_browse_everything.html.erb', type: :view do
  let(:model) { stub_model(GenericWork) }
  let(:form) { Hyrax::Forms::WorkForm.new(model, double) }
  let(:f) { double(object: form) }
  before do
    # allow(view).to receive(:parent).and_return(parent)
  end

  it 'shows user timing warning' do
    render 'hyrax/base/browse_everything', f: f
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_selector('div.alert-success', text: /Please note that if you upload a large number of files/i, count: 1)
  end
end
