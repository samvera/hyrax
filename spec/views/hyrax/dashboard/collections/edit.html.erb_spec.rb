# frozen_string_literal: true
RSpec.describe 'hyrax/dashboard/collections/edit.html.erb', type: :view do
  let(:collection_type) { stub_model(Hyrax::CollectionType) }
  let(:collection) { build :hyrax_collection }
  let(:form) { Hyrax::Forms::ResourceForm.for(resource: collection) }

  before do
    assign(:collection, collection)
    assign(:form, form)
    allow(Hyrax::CollectionType).to receive(:for).with(collection: collection).and_return(collection_type)
    stub_template '_form.html.erb' => 'my-edit-form partial'
    stub_template '_flash_msg.html.erb' => 'flash_msg partial'

    render
  end

  it 'displays the page' do
    expect(rendered).to have_content 'my-edit-form partial'
    expect(rendered).to have_content 'flash_msg partial'
  end
end
