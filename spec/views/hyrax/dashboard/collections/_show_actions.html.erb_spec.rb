# frozen_string_literal: true
RSpec.describe 'hyrax/dashboard/collections/_show_actions.html.erb', type: :view do
  let(:presenter) { double('Hyrax::CollectionPresenter', collection_type_is_nestable?: false, solr_document: solr_document, id: '123') }
  let(:solr_document) { double('Solr Document') }
  let(:can_destroy) { true }
  let(:can_edit) { true }

  before do
    allow(view).to receive(:presenter).and_return(presenter)
    # Must stub non-hyrax routes as engines don't have access to these routes
    allow(view).to receive_message_chain(:hyrax, :edit_dashboard_collection_path).with(presenter).and_return('/path/to/edit') # rubocop:disable RSpec/MessageChain
    allow(view).to receive_message_chain(:hyrax, :dashboard_collection_path).with(presenter).and_return('/path/to/destroy') # rubocop:disable RSpec/MessageChain

    allow(view).to receive(:can?).with(:edit, solr_document).and_return(can_edit)
    allow(view).to receive(:can?).with(:destroy, solr_document).and_return(can_destroy)
  end

  describe 'when user can edit the document' do
    let(:can_edit) { true }

    it 'renders edit collection link' do
      render
      expect(rendered).to have_link('Edit this collection', href: '/path/to/edit')
    end
  end
  describe 'when user cannot edit the document' do
    let(:can_edit) { false }

    it 'does not render edit collection link' do
      render
      expect(rendered).not_to have_link('Edit this collection', href: '/path/to/edit')
    end
  end

  describe 'nesting the collection within another collection' do
    context 'with nestable collection' do
      it 'renders add parent collection link' do
        allow(presenter).to receive(:collection_type_is_nestable?).and_return true
        allow(presenter).to receive(:user_can_nest_collection?).and_return true

        render
        expect(rendered).to have_button('Add existing collections to this collection')
      end
    end

    context 'with nestable collection but without permissions' do
      it 'does not render add parent collection link' do
        allow(presenter).to receive(:collection_type_is_nestable?).and_return true
        allow(presenter).to receive(:user_can_nest_collection?).and_return false

        render
        expect(rendered).not_to have_button('Add existing collections to this collection')
      end
    end

    context 'with non-nestable collection' do
      it 'does not render add parent collection link' do
        render
        expect(rendered).not_to have_button('Nest this collection')
      end
    end
  end

  describe 'when user can destroy the document' do
    it 'renders a link to destroy the document' do
      render
      expect(rendered).to have_link('Delete this collection', href: '/path/to/destroy')
    end
  end
  describe 'when user cannot destroy the document' do
    let(:can_destroy) { false }

    it 'does not render a link to destroy the document' do
      render
      expect(rendered).not_to have_link('Delete this collection', href: '/path/to/destroy')
    end
  end
end
