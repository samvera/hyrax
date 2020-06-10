RSpec.describe 'shared/_select_work_type_modal.html.erb', type: :view do
  let(:presenter) { instance_double Hyrax::SelectTypeListPresenter }
  let(:row1) do
    Hyrax::SelectTypePresenter.new(GenericWork)
  end
  let(:row2) do
    Hyrax::SelectTypePresenter.new(NamespacedWorks::NestedWork)
  end

  before do
    allow(presenter).to receive(:each).and_yield(row1).and_yield(row2)
    # Because there is no i18n set up for this work type
    allow(row2).to receive(:name).and_return('Nested Work')
  end

  context 'when no collections id' do
    before do
      render 'shared/select_work_type_modal', create_work_presenter: presenter
    end

    it 'draws the modal' do
      expect(rendered).to have_selector '#worktypes-to-create.modal'
      expect(rendered).to have_content 'Generic Work'
      expect(rendered).to have_content 'Nested Work'
      expect(rendered).to have_selector 'input[type="radio"][data-single="/concern/generic_works/new"][data-batch="/batch_uploads/new?payload_concern=GenericWork"]'
      expect(rendered).to have_selector 'input[type="radio"][data-single="/concern/namespaced_works/nested_works/new"][data-batch="/batch_uploads/new?payload_concern=NamespacedWorks%3A%3ANestedWork"]'
    end
  end

  context 'when collection id exists' do
    before do
      allow(view).to receive(:params).and_return(id: '1', controller: 'hyrax/dashboard/collections')
      render 'shared/select_work_type_modal', create_work_presenter: presenter
    end
    it 'draws the modal with collection id' do
      expect(rendered).to have_selector 'input[type="radio"][data-single="/concern/generic_works/new?add_works_to_collection=1"][data-batch="/batch_uploads/new?add_works_to_collection=1&payload_concern=GenericWork"]' # rubocop:disable Layout/LineLength
      expect(rendered).to have_selector 'input[type="radio"][data-single="/concern/namespaced_works/nested_works/new?add_works_to_collection=1"][data-batch="/batch_uploads/new?add_works_to_collection=1&payload_concern=NamespacedWorks%3A%3ANestedWork"]' # rubocop:disable Layout/LineLength
    end
  end

  context 'when add_works_to_collection exists' do
    before do
      allow(view).to receive(:params).and_return(add_works_to_collection: '1')
      render 'shared/select_work_type_modal', create_work_presenter: presenter
    end
    it 'draws the modal with collection id' do
      expect(rendered).to have_selector 'input[type="radio"][data-single="/concern/generic_works/new?add_works_to_collection=1"][data-batch="/batch_uploads/new?add_works_to_collection=1&payload_concern=GenericWork"]' # rubocop:disable Layout/LineLength
      expect(rendered).to have_selector 'input[type="radio"][data-single="/concern/namespaced_works/nested_works/new?add_works_to_collection=1"][data-batch="/batch_uploads/new?add_works_to_collection=1&payload_concern=NamespacedWorks%3A%3ANestedWork"]' # rubocop:disable Layout/LineLength
    end
  end
end
