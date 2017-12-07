RSpec.describe 'hyrax/file_sets/_versioning.html.erb', type: :view do
  let(:file_set) { stub_model(FileSet) }
  let(:change_set) { Hyrax::FileSetChangeSet.new(file_set) }

  before do
    render 'hyrax/file_sets/versioning', change_set: change_set
  end

  context "without additional users" do
    it "draws the new version form without error" do
      expect(rendered).to have_css("input[name='file_set[files][]']")
    end
  end
end
