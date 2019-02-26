# frozen_string_literal: true
RSpec.describe 'hyrax/file_sets/_permission_form.html.erb', type: :view do
  let(:file_set) do
    stub_model(FileSet, id: '123',
                        depositor: 'bob',
                        resource_type: ['Dataset'])
  end

  let(:form) do
    view.simple_form_for(file_set, url: '/update') do |fs_form|
      return fs_form
    end
  end

  before do
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    allow(view).to receive(:f).and_return(form)
    view.lookup_context.prefixes.push 'hyrax/base'
    stub_template "_currently_shared.html.erb" => "<span class='base-currently-shared'>base/currently_shared</span>"
    view.extend Hyrax::PermissionsHelper
    render
  end

  it "draws the permissions form without error" do
    expect(rendered).to have_css("input#new_user_name_skel")
    expect(rendered).to have_content("base/currently_shared")
  end
end
