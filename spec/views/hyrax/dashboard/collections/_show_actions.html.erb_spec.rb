RSpec.describe 'hyrax/dashboard/collections/_show_actions.html.erb', type: :view do
  let(:presenter) { double('Hyrax::CollectionPresenter', collection_type_is_nestable?: is_nestable, solr_document: solr_document, id: '123') }
  let(:solr_document) { double('Solr Document') }
  let(:is_nestable) { true }
  let(:can_destroy) { true }
  let(:can_edit) { true }

  before do
    allow(view).to receive(:presenter).and_return(presenter)
    # Must stub non-hyrax routes as engines don't have access to these routes
    allow(view).to receive(:edit_dashboard_collection_path).with(presenter).and_return('/path/to/edit')
    allow(view).to receive(:collection_path).with(presenter).and_return('/path/to/destroy')

    allow(view).to receive(:can?).with(:edit, solr_document).and_return(can_edit)
    allow(view).to receive(:can?).with(:destroy, solr_document).and_return(can_destroy)
  end
  describe 'when user can edit the document' do
    let(:can_edit) { true }

    it 'renders edit collection link' do
      render
      expect(rendered).to have_css('.actions-controls-collections .btn[href="/path/to/edit"]')
    end
    it 'renders add_works_to_collection link' do
      render
      expect(rendered).to have_css(".actions-controls-collections .btn[href='#{hyrax.my_works_path(add_works_to_collection: presenter.id)}']")
    end
    describe 'when the collection_type is nestable' do
      it 'renders a link to add_collections to this collection' do
        render
        expect(rendered).to have_css(".actions-controls-collections .btn[href='#{hyrax.dashboard_new_nest_collection_within_path(child_id: presenter.id)}']")
      end
    end
    describe 'when the collection_type is not nestable' do
      let(:is_nestable) { false }

      it 'does not render a link to add_collections to this collection' do
        render
        expect(rendered).not_to have_css(".actions-controls-collections .btn[href='/TODO/NEST_COLLECTION']")
      end
    end
  end
  describe 'when user cannot edit the document' do
    let(:can_edit) { false }

    it 'does not render edit collection link' do
      render
      expect(rendered).not_to have_css('.actions-controls-collections .btn[href="/path/to/edit"]')
    end

    it 'does not render add_works_to_collection link' do
      render
      expect(rendered).not_to have_css(".actions-controls-collections .btn[href='#{hyrax.my_works_path(add_works_to_collection: presenter.id)}']")
    end

    describe 'when the collection_type is not nestable' do
      it 'does not render a link to add_collections to this collection' do
        render
        expect(rendered).not_to have_css(".actions-controls-collections .btn[href='/TODO/NEST_COLLECTION']")
      end
    end
    describe 'when the collection_type is nestable' do
      it 'does not render a link to add_collections to this collection' do
        render
        expect(rendered).not_to have_css(".actions-controls-collections .btn[href='/TODO/NEST_COLLECTION']")
      end
    end
  end
  describe 'when user can destroy the document' do
    it 'renders a link to destroy the document' do
      render
      expect(rendered).to have_css('.actions-controls-collections .btn[href="/path/to/destroy"]')
    end
  end
  describe 'when user cannot destroy the document' do
    let(:can_destroy) { false }

    it 'does not render a link to destroy the document' do
      render
      expect(rendered).not_to have_css('.actions-controls-collections .btn[href="/path/to/destroy"]')
    end
  end
end
