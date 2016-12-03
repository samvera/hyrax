describe 'hyrax/file_sets/_versioning.html.erb', type: :view do
  let(:file_set) { stub_model(FileSet) }

  before do
    allow(view).to receive(:curation_concern).and_return(file_set)
    assign(:version_list, [])
    render
  end

  context "without additional users" do
    it "draws the new version form without error" do
      expect(rendered).to have_css("input[name='file_set[files][]']")
    end
  end
end
