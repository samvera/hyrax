RSpec.describe 'hyrax/dashboard/collections/show.html.erb', type: :view do
  let(:document) do
    SolrDocument.new(id: 'xyz123z4',
                     'title_tesim' => ['Make Collections Great Again'],
                     'rights_tesim' => ["http://creativecommons.org/licenses/by-sa/3.0/us/"])
  end
  let(:ability) { double }
  let(:collection) { mock_model(Collection) }
  let(:presenter) { Hyrax::CollectionPresenter.new(document, ability) }
  let(:collection_type) { double }

  before do
    user = stub_model(User)
    allow(document).to receive(:hydra_model).and_return(::Collection)
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:can?).with(:edit, document).and_return(true)
    allow(view).to receive(:can?).with(:destroy, document).and_return(true)
    allow(view).to receive(:current_ability).and_return(ability)
    allow(ability).to receive(:current_user).and_return(user)

    allow(Collection).to receive(:find).with(document.id).and_return(collection)

    allow(presenter).to receive(:total_items).and_return(0)
    allow(presenter).to receive(:collection_type).and_return(collection_type)
    allow(presenter).to receive(:subcollection_count).and_return(0)
    assign(:parent_collection_count, 0)
    assign(:members_count, 0)

    allow(collection_type).to receive(:nestable?).and_return(true)
    allow(collection_type).to receive(:title).and_return("User Collection")
    allow(collection_type).to receive(:badge_color).and_return("#ffa510")

    assign(:presenter, presenter)
    # Stub route because view specs don't handle engine routes
    allow(view).to receive(:edit_dashboard_collection_path).and_return("/dashboard/collection/123/edit")
    allow(view).to receive(:dashboard_collection_path).and_return("/dashboard/collection/123")
    allow(view).to receive(:collection_path).and_return("/collection/123")

    stub_template '_search_form.html.erb' => 'search form'
    stub_template 'hyrax/dashboard/collections/_sort_and_per_page.html.erb' => 'sort and per page'
    stub_template '_document_list.html.erb' => 'document list'
    # This is tested ./spec/views/hyrax/dashboard/collections/_show_actions.html.erb_spec.rb
    stub_template '_show_actions.html.erb' => '<div class="stubbed-actions">THE COLLECTION ACTIONS</div>'
    stub_template '_show_subcollection_actions.html.erb' => '<div class="stubbed-actions">THE SUBCOLLECTION ACTIONS</div>'
    stub_template '_show_add_items_actions.html.erb' => '<div class="stubbed-actions">THE ADD ITEMS ACTIONS</div>'
    stub_template '_show_parent_collections.html.erb' => '<div class="stubbed-actions">THE PARENT COLLECTIONS LIST</div>'
    stub_template '_subcollection_list.html.erb' => '<div class="stubbed-actions">THE SUB-COLLECTIONS LIST</div>'
    stub_template 'hyrax/collections/_paginate.html.erb' => 'paginate'
    stub_template 'hyrax/collections/_media_display.html.erb' => '<span class="fa fa-cubes collection-icon-search"></span>'
    stub_template 'hyrax/my/collections/_modal_add_to_collection.html.erb' => 'modal add as subcollection'
    stub_template 'hyrax/my/collections/_modal_add_subcollection.html.erb' => 'modal add as parent'
  end

  it 'draws the page' do
    render
    # Making sure that we are verifying that the _show_actions.html.erb is rendering
    expect(rendered).to have_css('.stubbed-actions', text: 'THE COLLECTION ACTIONS')
    expect(rendered).to have_css('.stubbed-actions', text: 'THE SUBCOLLECTION ACTIONS')
    expect(rendered).to have_css('.stubbed-actions', text: 'THE ADD ITEMS ACTIONS')
    expect(rendered).to match '<span class="fa fa-cubes collection-icon-search"></span>'
    expect(rendered).not_to have_text('Search Results within this Collection')
  end

  context 'with a not-nested collection_type' do
    before do
      allow(presenter).to receive(:subcollection_count).and_return(0)
      render
    end
    it 'draws the page' do
      allow(collection_type).to receive(:nestable?).and_return(false)
      # Making sure that we are verifying that the _show_actions.html.erb is rendering
      expect(rendered).to have_css('.stubbed-actions', text: 'THE COLLECTION ACTIONS')
      expect(rendered).to have_css('.stubbed-actions', text: 'THE SUBCOLLECTION ACTIONS')
      expect(rendered).to have_css('.stubbed-actions', text: 'THE ADD ITEMS ACTIONS')
      expect(rendered).to match '<span class="fa fa-cubes collection-icon-search"></span>'
      expect(rendered).not_to have_text('Search Results within this Collection')
    end
  end

  context 'when search results exist' do
    before do
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(Hyrax::CollectionsHelper).to receive(:has_collection_search_parameters?).and_return(true)
      # rubocop:enable RSpec/AnyInstance
    end

    context 'and only works are in search results' do
      before do
        assign(:members_count, 1)
        render
      end

      it 'shows results header' do
        expect(rendered).to have_text('Search Results within this Collection')
        expect(rendered).to have_css('.stubbed-actions', text: 'THE COLLECTION ACTIONS')
        expect(rendered).not_to have_css('.stubbed-actions', text: 'THE SUBCOLLECTION ACTIONS')
        expect(rendered).not_to have_css('.stubbed-actions', text: 'THE ADD ITEMS ACTIONS')
      end
    end

    context ' and only subcollections are in search results' do
      before do
        allow(presenter).to receive(:subcollection_count).and_return(1)
        assign(:members_count, 0)
        render
      end

      it 'shows results header' do
        expect(rendered).to have_text('Search Results within this Collection')
        expect(rendered).to have_css('.stubbed-actions', text: 'THE COLLECTION ACTIONS')
        expect(rendered).not_to have_css('.stubbed-actions', text: 'THE SUBCOLLECTION ACTIONS')
        expect(rendered).not_to have_css('.stubbed-actions', text: 'THE ADD ITEMS ACTIONS')
      end
    end
  end
end
