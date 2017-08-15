RSpec.describe 'shared/_select_work_type_modal.html.erb', type: :view do
  let(:presenter) { instance_double Hyrax::SelectTypeListPresenter }
  let(:row1) do
    Hyrax::SelectTypePresenter.new(GenericWork)
  end
  let(:row2) do
    Hyrax::SelectTypePresenter.new(RareBooks::Atlas)
  end

  before do
    allow(presenter).to receive(:each).and_yield(row1).and_yield(row2)
    allow(view).to receive(:create_work_presenter).and_return(presenter)
    # Because there is no i18n set up for this work type
    allow(row2).to receive(:name).and_return('Atlas')
    render
  end

  it 'draws the modal' do
    expect(rendered).to have_selector '#worktypes-to-create.modal'
    expect(rendered).to have_content 'Generic Work'
    expect(rendered).to have_content 'Atlas'
    expect(rendered).to have_selector 'input[type="radio"][data-single="/concern/generic_works/new"][data-batch="/batch_uploads/new?payload_concern=GenericWork"]'
    expect(rendered).to have_selector 'input[type="radio"][data-single="/concern/rare_books/atlases/new"][data-batch="/batch_uploads/new?payload_concern=RareBooks%3A%3AAtlas"]'
  end
end
