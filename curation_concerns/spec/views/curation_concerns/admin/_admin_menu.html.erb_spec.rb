require 'spec_helper'

RSpec.describe "admin_menu.html.erb" do
  let(:configuration) do
    {
      menu: {
        index: {}
      }
    }
  end
  before do
    allow(view).to receive(:action_name).and_return(:index)
    render partial: "curation_concerns/admin/admin_menu", locals: { configuration: configuration }
  end
  context "when there's an item in the index menu" do
    it "makes a link to the right action" do
      expect(rendered).to have_link "Admin Dashboard", href: curation_concerns.admin_index_path
    end
    it "marks the current page as active" do
      expect(rendered).to have_selector "li.active > a"
    end
  end
end
