
describe 'sufia/batch_edits/_check_all.html.erb', type: :view do
  before do
    allow(controller).to receive(:controller_name).and_return('my')
    view.lookup_context.prefixes.push 'sufia/my'
    render
  end

  it 'renders actions for my items' do
    expect(rendered).to have_selector("li[data-behavior='batch-edit-select-none']")
    expect(rendered).to have_selector("li[data-behavior='batch-edit-select-page']")
  end
end
