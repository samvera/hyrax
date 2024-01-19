# frozen_string_literal: true
RSpec.describe 'hyrax/base/_currently_shared.html.erb', type: :view do
  let(:user) { stub_model(User) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(work).to receive(:depositor).and_return(user)
  end

  context 'with ActiveFedora', :active_fedora do
    let(:work) do
      stub_model(GenericWork, id: '456')
    end

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

    it "draws the permissions form without error" do
      render partial: 'hyrax/base/currently_shared', locals: { f: file_set_form }

      # actual testing of who gets what permission access is done in
      # the EditPermissionsService (is it?!)
      expect(rendered).to have_content("Depositor")
    end
  end

  context "with ResourceForm", valkyrie_adapter: :test_adapter do
    let(:form) { Hyrax::Forms::ResourceForm.for(resource: work).prepopulate! }
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :public) }

    let(:file_set_form) do
      view.simple_form_for(form, url: '/update') { |form| return form }
    end

    it "includes permissions" do
      render partial: "hyrax/base/currently_shared", locals: { f: file_set_form }

      expect(rendered).to include "group/public"
    end
  end
end
