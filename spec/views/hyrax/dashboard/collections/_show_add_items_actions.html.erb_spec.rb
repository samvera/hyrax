RSpec.describe 'hyrax/dashboard/collections/_show_add_items_actions.html.erb', type: :view do
  let(:presenter) { double('Hyrax::CollectionPresenter', solr_document: solr_document, id: '123') }
  let(:solr_document) { double('Solr Document') }
  let(:can_edit) { true }

  before do
    allow(view).to receive(:presenter).and_return(presenter)

    allow(view).to receive(:can?).with(:edit, solr_document).and_return(can_edit) # TODO: probably should be :deposit -- dependency on collection participants
  end
  describe 'when user can edit the document' do
    let(:can_edit) { true }

    it 'renders add_existing_works_to_collection link' do
      render
      expect(rendered).to have_css(".actions-controls-collections .btn[href='#{hyrax.my_works_path(add_works_to_collection: presenter.id)}']")
    end
    it 'renders add_new_work_to_collection link' do
      render
      expect(rendered).to have_link("Add new work")
    end
  end
  describe 'when user cannot edit the document' do
    let(:can_edit) { false }

    it 'does not render add_works_to_collection link' do
      render
      expect(rendered).not_to have_css(".actions-controls-collections .btn[href='#{hyrax.my_works_path(add_works_to_collection: presenter.id)}']")
    end
  end
end
