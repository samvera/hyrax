RSpec.describe 'hyrax/file_sets/_permission_form.html.erb', type: :view do
  let(:file_set) do
    stub_model(FileSet, id: '123',
                        depositor: 'bob',
                        resource_type: ['Dataset'])
  end
  let(:change_set) { Hyrax::FileSetChangeSet.new(file_set).prepopulate! }

  let(:form) do
    view.simple_form_for(change_set, url: '/update') do |fs_form|
      return fs_form
    end
  end

  before do
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    allow(view).to receive(:f).and_return(form)
    view.lookup_context.prefixes.push 'hyrax/base'
    view.extend Hyrax::PermissionsHelper
    render
  end

  context "without additional users" do
    it "draws the permissions form without error" do
      expect(rendered).to have_css("input#new_user_name_skel")
      expect(rendered).not_to have_css("button.remove_perm")
    end
  end

  context "with additional users" do
    let(:file_set) do
      stub_model(FileSet, id: '123',
                          depositor: 'bob',
                          resource_type: ['Dataset'],
                          edit_users: ['bob', 'joe@example.com'],
                          read_users: ['public'])
    end

    it "draws the permissions form without error" do
      expect(rendered).to have_css("input#new_user_name_skel")
      expect(rendered).to have_css("button.remove_perm", count: 1) # depositor and public should be filtered out
      expect(rendered).to have_css("button.remove_perm[data-index='1']")
    end
  end
end
