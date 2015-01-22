require 'spec_helper'

describe 'generic_files/_permission_form.html.erb', :type => :view do
  let(:generic_file) {
    stub_model(GenericFile, id: '123',
        depositor: 'bob',
        resource_type: ['Dataset'])
  }

  let(:form) do
    form_for(generic_file, url: '/update') do |gf_form|
      return gf_form
    end
  end

  before do
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    allow(generic_file).to receive(:permissions).and_return(permissions)
    allow(view).to receive(:f).and_return(form)
    render
  end

  context "without additional users" do
    let(:permissions) { [] }

    it "should draw the permissions form without error" do
      expect(rendered).to have_css("input#new_user_name_skel")
      expect(rendered).not_to have_css("button.remove_perm")
    end
  end

  context "with additional users" do
    let(:depositor_permission) { Hydra::AccessControls::Permission.new(id: '123', name: 'bob', type: 'person', access: 'edit') }
    let(:public_permission) { Hydra::AccessControls::Permission.new(id: '124', name: 'public', type: 'group', access: 'read') }
    let(:other_permission) { Hydra::AccessControls::Permission.new(id: '125', name: 'joe@example.com', type: 'person', access: 'edit') }
    let(:permissions) { [ depositor_permission, public_permission, other_permission] }

    it "should draw the permissions form without error" do
      expect(rendered).to have_css("input#new_user_name_skel")
      expect(rendered).to have_css("button.remove_perm", count: 1) # depositor and public should be filtered out
      expect(rendered).to have_css("button.remove_perm[data-index='2']")
    end
  end

end
