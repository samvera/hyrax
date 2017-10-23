RSpec.describe 'hyrax/dashboard/collections/_show_subcollection_actions.html.erb', type: :view do
  let(:presenter) { double('Hyrax::CollectionPresenter', collection_type_is_nestable?: is_nestable, solr_document: solr_document, id: '123') }
  let(:solr_document) { double('Solr Document') }
  let(:is_nestable) { true }
  let(:can_edit) { true }

  before do
    allow(view).to receive(:presenter).and_return(presenter)

    allow(view).to receive(:can?).with(:edit, solr_document).and_return(can_edit) # TODO: probably should be :deposit -- dependency on collection participants
  end
  describe 'when user can edit the document' do
    let(:can_edit) { true }

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

    describe 'when the collection_type is nestable' do
      it 'does not render a link to add_collections to this collection' do
        render
        expect(rendered).not_to have_css(".actions-controls-collections .btn[href='/TODO/NEST_COLLECTION']")
      end
    end
  end
end
