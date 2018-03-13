RSpec.describe 'hyrax/file_sets/_actions.html.erb', type: :view do
  let(:file_set) { stub_model(FileSet) }

  before do
    allow(view).to receive(:can?).with(:edit, file_set.id).and_return(false)
    allow(view).to receive(:can?).with(:destroy, file_set.id).and_return(false)
    allow(view).to receive(:can?).with(:download, file_set.id).and_return(true)
    render 'hyrax/file_sets/actions', file_set: file_set
  end

  it "includes google analytics data in the download link" do
    expect(rendered).to have_css('a#file_download')
    expect(rendered).to have_selector("a[data-label=\"#{file_set.id}\"]")
  end
end
