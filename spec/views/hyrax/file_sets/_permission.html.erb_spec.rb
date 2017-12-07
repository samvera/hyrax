RSpec.describe 'hyrax/file_sets/_permission.html.erb', type: :view do
  let(:file_set) { stub_model(FileSet) }
  let(:change_set) { Hyrax::FileSetChangeSet.new(file_set) }

  before do
    stub_template "hyrax/file_sets/_permission_form.html.erb" => 'a form'
    render 'hyrax/file_sets/permission', change_set: change_set
  end

  context "without additional users" do
    it "draws the permissions form without error" do
      expect(rendered).to have_css('form#permission[data-param-key="file_set"]')
    end
  end
end
