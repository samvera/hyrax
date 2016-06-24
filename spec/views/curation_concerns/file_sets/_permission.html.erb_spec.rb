require 'spec_helper'

describe 'curation_concerns/file_sets/_permission.html.erb', type: :view do
  let(:file_set) { stub_model(FileSet) }

  before do
    stub_template "curation_concerns/file_sets/_permission_form.html.erb" => 'a form'
    render 'curation_concerns/file_sets/permission', file_set: file_set
  end

  context "without additional users" do
    it "draws the permissions form without error" do
      expect(rendered).to have_css('form#permission[data-param-key="file_set"]')
    end
  end
end
