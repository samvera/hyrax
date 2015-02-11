require 'spec_helper'

describe 'collections/_form_representative_image.html.erb' do
  let(:file) { build(:generic_file, title: ['birds.jpg']) }
  let(:work) { build(:generic_work, generic_files: [ file ]) }
  let(:collection) { create(:collection, members: [ work ]) }
  let(:form) { ActionView::Helpers::FormBuilder.new(:collection, collection, view, {}) }

  before do
    allow(collection).to receive(:persisted?).and_return(true)
    allow(collection).to receive(:members).and_return([work]) # This allows us to skip saving & reloading the collection
    allow(view).to receive(:curation_concern).and_return(collection)
    allow(view).to receive(:f).and_return(form)
  end

  it "should have a list of the generic files images" do
    render partial:'collections/form_representative_image.html.erb'
    expect(rendered).to have_selector "select#collection_representative option[value='#{file.id}']",
      text: 'birds.jpg'
  end
end
