require 'spec_helper'

RSpec.describe 'hyrax/admin/collection_types/index.html.erb', type: :view, clean_repo: true do
  before do
    assign(:collection_types, [
             FactoryGirl.create(:user_collection_type),
             FactoryGirl.create(:admin_set_collection_type),
             FactoryGirl.create(:collection_type, title: 'Test Title 1'),
             FactoryGirl.create(:collection_type, title: 'Test Title 2')
           ])
    render
  end

  it 'lists all the collection_types' do
    expect(rendered).to have_content('Admin Set')
    expect(rendered).to have_content('User Collection')
    expect(rendered).to have_content('Test Title 1')
    expect(rendered).to have_content('Test Title 2')
  end

  it 'displays the collection type count correctly' do
    expect(rendered).to have_content '4 collection types in this repository'
  end

  it 'has edit buttons for all' do
    expect(rendered).to have_button('Edit', count: 4)
  end

  it 'has delete buttons for non-special collection types' do
    expect(rendered).to have_button('Delete', count: 2)
  end
end
