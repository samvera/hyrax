# frozen_string_literal: true
RSpec.describe 'hyrax/dashboard/collections/_show_subcollection_actions.html.erb', type: :view do
  let(:presenter) do
    double('Hyrax::CollectionPresenter',
           collection_type_is_nestable?: is_nestable,
           collection: collection,
           id: '123',
           user_can_nest_collection?: can_deposit,
           user_can_create_new_nest_collection?: can_create)
  end
  let(:collection) { double('A Collection') }
  let(:is_nestable) { true }
  let(:can_deposit) { true }
  let(:can_create) { true }

  before do
    allow(view).to receive(:presenter).and_return(presenter)
  end

  describe 'when user has permission to create subcollections' do
    before do
      render
    end

    it 'renders a links to nest subcollection options' do
      expect(rendered).to have_button(I18n.t('hyrax.collection.actions.nest_collections.desc'))
      expect(rendered).to have_css(".btn[href='#{hyrax.dashboard_create_subcollection_under_path(parent_id: presenter.id)}']")
    end
  end

  describe 'when the collection_type is not nestable' do
    let(:is_nestable) { false }

    it 'does not render a link to add_collections to this collection' do
      render
      expect(rendered).not_to have_css(".actions-controls-collections .btn[href='#{hyrax.dashboard_create_subcollection_under_path(parent_id: presenter.id)}']")
    end
  end

  describe 'when user has no nesting permissions' do
    let(:can_deposit) { false }

    describe 'when the collection_type is nestable' do
      it 'does not render a either nesting option' do
        render
        expect(rendered).not_to have_button(I18n.t('hyrax.collection.actions.nest_collections.desc'))
        expect(rendered).not_to have_css(".actions-controls-collections .btn[href='#{hyrax.dashboard_create_subcollection_under_path(parent_id: presenter.id)}']")
      end
    end
  end

  describe 'when user cannot create new collection' do
    let(:can_create) { false }

    describe 'when the collection_type is nestable' do
      it 'does not render a button to create a new collection' do
        render
        expect(rendered).to have_button(I18n.t('hyrax.collection.actions.nest_collections.desc'))
        expect(rendered).not_to have_css(".actions-controls-collections .btn[href='#{hyrax.dashboard_create_subcollection_under_path(parent_id: presenter.id)}']")
      end
    end
  end
end
