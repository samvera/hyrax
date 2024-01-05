# frozen_string_literal: true
RSpec.describe 'hyrax/file_sets/_permission_form.html.erb', type: :view do
  let(:file_set) do
    if Hyrax.config.disable_wings
      # NOTE: stubbing the lease and embargo attributes is necessary here to avoid creating an associated embargo object that
      #   Hyrax::LeaseabilityBehavior can process.
      stub_model(FileSet, id: '123',
                          depositor: 'bob',
                          resource_type: ['Dataset'],
                          embargo_release_date: Time.zone.today + 2,
                          lease_expiration_date: Time.zone.today + 2,
                          visibility_during_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
                          visibility_after_embargo: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC,
                          visibility_during_lease: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
                          visibility_after_lease: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
    else
      stub_model(FileSet, id: '123',
                          depositor: 'bob',
                          resource_type: ['Dataset'])
    end
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
