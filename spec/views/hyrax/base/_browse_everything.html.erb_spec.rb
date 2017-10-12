RSpec.describe 'hyrax/base/_browse_everything.html.erb', type: :view do
  let(:model) { stub_model(GenericWork) }
  let(:change_set) { Hyrax::GenericWorkChangeSet.new(model) }
  let(:f) { double(object: change_set) }

  before do
    # TODO: stub_model is not stubbing new_record? correctly on ActiveFedora models.
    allow(model).to receive(:new_record?).and_return(false)
  end

  it 'shows user timing warning' do
    render 'hyrax/base/browse_everything', f: f
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_selector('div.alert-success', text: /Please note that if you upload a large number of files/i, count: 1)
    expect(page).to have_selector("button[id='browse-btn'][data-target='#edit_generic_work_#{change_set.model.id}']")
  end
end
