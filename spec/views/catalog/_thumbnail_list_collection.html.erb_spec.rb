describe 'catalog/_thumbnail_list_collection.html.erb', type: :view do
  before do
    stub_template 'catalog/_thumbnail_list_collection.html.erb' => '<div class="col-sm-3"><span class="fa fa-cubes collection-icon-search"></span></div>'
    render
  end

  it 'displays the collection icon in the search results' do
    expect(rendered).to match '<div class="col-sm-3"><span class="fa fa-cubes collection-icon-search"></span></div>'
  end
end
