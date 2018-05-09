RSpec.describe 'hyrax/dashboard/collections/_show_add_items_actions.html.erb', type: :view do
  let(:presenter) { double('Hyrax::CollectionPresenter', solr_document: solr_document, id: '123', title: 'Collection 1') }
  let(:solr_document) { double('Solr Document') }
  let(:can_deposit) { true }

  before do
    allow(view).to receive(:presenter).and_return(presenter)
    allow(presenter).to receive(:create_many_work_types?).and_return(true)
    assign(:presenter, presenter)
    allow(view).to receive(:can?).with(:deposit, solr_document).and_return(can_deposit)
  end
  describe 'when user can edit the document' do
    let(:can_deposit) { true }

    it 'renders add_existing_works_to_collection link' do
      render
      expect(rendered).to have_css(".btn[href='#{hyrax.my_works_path(add_works_to_collection: presenter.id,
                                                                     add_works_to_collection_label: presenter.title)}']")
    end
    it 'renders add_new_work_to_collection link' do
      render
      expect(rendered).to have_link("Deposit new work through this collection")
    end
  end
  describe 'when user cannot edit the document' do
    let(:can_deposit) { false }

    it 'does not render add_works_to_collection link' do
      render
      expect(rendered).not_to have_css(".actions-controls-collections .btn[href='#{hyrax.my_works_path(add_works_to_collection: presenter.id,
                                                                                                       add_works_to_collection_label: presenter.title)}']")
    end
  end

  describe 'when there is only one work type' do
    let(:can_deposit) { true }

    it 'renders add_new_work_to_collection link' do
      allow(presenter).to receive(:create_many_work_types?).and_return(false)
      allow(presenter).to receive(:first_work_type).and_return(GenericWork)

      render
      expect(rendered).to have_link("Deposit new work through this collection")
    end
  end
end
