# frozen_string_literal: true
RSpec.describe 'hyrax/base/_currently_shared.html.erb', type: :view do
  let(:user) { stub_model(User) }
  let(:work) do
    stub_model(GenericWork, id: '456')
  end
  # let(:admin_set) { stub_model(AdminSet, id: '789') }
  let(:file_set) do
    stub_model(FileSet, id: '123',
                        depositor: 'bob',
                        resource_type: ['Dataset'], in_works: [work])
  end
  let(:file_set_form) do
    view.simple_form_for(file_set, url: '/update') do |fs_form|
      return fs_form
    end
  end

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(view).to receive(:f).and_return(file_set_form)
    allow(work).to receive(:depositor).and_return(user)
    allow(file_set).to receive(:permissions).and_return(permissions)
    allow(work).to receive(:member_of_collections).and_return([])
    allow(work).to receive(:admin_set_id).and_return([])
    render
  end

  context "it displays the form" do
    let(:permissions) { [] }

    it "draws the permissions form without error" do
      # actual testing of who gets what permission access is done in the EditPermissionsService
      expect(rendered).to have_content("Depositor")
    end
  end
end
