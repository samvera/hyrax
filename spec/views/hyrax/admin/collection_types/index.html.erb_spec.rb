require 'spec_helper'

RSpec.describe 'hyrax/admin/collection_types/index.html.erb', type: :view, clean_repo: true do
  before do
    assign(:collection_types, [
             FactoryGirl.create(:collection_type, title: 'Test Title 1'),
             FactoryGirl.create(:collection_type, title: 'Test Title 2')
           ])
    render
  end

  it 'lists all the collection_types' do
    expect(rendered).to have_content('Test Title 1')
    expect(rendered).to have_content('Test Title 2')
  end

  it 'displays the collection type count correctly' do
    expect(rendered).to have_content '2 collection types in this repository'
  end
end
