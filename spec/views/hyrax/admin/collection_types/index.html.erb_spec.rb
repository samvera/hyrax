require 'spec_helper'

RSpec.describe 'hyrax/admin/collection_types/index.html.erb', type: :view, clean_repo: true do
  before do
    assign(:collection_types, [
             create(:user_collection_type),
             create(:admin_set_collection_type),
             FactoryBot.create(:collection_type, title: 'Test Title 1'),
             FactoryBot.create(:collection_type, title: 'Test Title 2')
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

  it 'has edit buttons for custom and predefined collection types' do
    expect(rendered).to have_link('Edit', count: 4)
  end

  it 'has delete buttons for custom collection types' do
    # 2 delete buttons for the custom collection types and 1 for the delete modal
    expect(rendered).to have_button('Delete', count: 3)
  end

  it 'has delete buttons with attribute for link to faceted index page' do
    expect(rendered).to have_selector(:css, 'button[data-collection-type-index]', count: 2)
  end

  it 'has view collections buttons for collection types with existing collections' do
    expect(rendered).to have_link('View collections of this type', count: 1)
  end
end
