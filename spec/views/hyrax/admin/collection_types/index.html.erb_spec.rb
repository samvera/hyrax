# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'hyrax/admin/collection_types/index.html.erb', type: :view do
  let(:user_collection_type) do
    stub_model(Hyrax::CollectionType,
               collections: [],
               title: 'User Collection')
  end
  let(:admin_set_collection_type) do
    stub_model(Hyrax::CollectionType,
               collections: [],
               title: 'Admin Set')
  end
  let(:custom1) do
    stub_model(Hyrax::CollectionType,
               collections: [],
               title: 'Test Title 1')
  end
  let(:custom2) do
    stub_model(Hyrax::CollectionType,
               collections: [],
               title: 'Test Title 2')
  end

  before do
    assign(:collection_types, [
             user_collection_type,
             admin_set_collection_type,
             custom1,
             custom2
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
    expect(rendered).to have_content '4 collection types'
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
