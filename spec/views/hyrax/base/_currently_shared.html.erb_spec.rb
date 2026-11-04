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
                          resource_type: ['Dataset'], in_works: [work],
                          edit_users: ['carol@example.com'])
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

    it "sends each editable grant's agent" do
      render partial: 'hyrax/base/currently_shared', locals: { f: file_set_form }
      page = Capybara::Node::Simple.new(rendered)

      expect(page).to have_field(type: 'hidden', with: 'person', name: /\[permissions_attributes\]\[\d+\]\[type\]/)
      expect(page).to have_field(type: 'hidden', with: 'carol@example.com', name: /\[permissions_attributes\]\[\d+\]\[name\]/)
    end
  end

  context "with ResourceForm", valkyrie_adapter: :test_adapter do
    let(:form) do
      f = Hyrax::Forms::ResourceForm.for(resource: work)
      f.admin_set_id = work.admin_set_id.to_s if f.respond_to?(:admin_set_id=)
      f.prepopulate!
      f
    end
    let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :public, read_groups: ['archivists']) }

    let(:file_set_form) do
      view.simple_form_for(form, url: '/update') { |form| return form }
    end

    it "lists shared groups and leaves the public group to the visibility setting" do
      render partial: "hyrax/base/currently_shared", locals: { f: file_set_form }

      expect(rendered).to include "archivists"
      expect(rendered).not_to include "public"
    end

    it "sends each editable grant's agent, so it can be removed" do
      render partial: "hyrax/base/currently_shared", locals: { f: file_set_form }
      page = Capybara::Node::Simple.new(rendered)

      expect(page).to have_field(type: 'hidden', with: 'group', name: /\[permissions_attributes\]\[\d+\]\[type\]/)
      expect(page).to have_field(type: 'hidden', with: 'archivists', name: /\[permissions_attributes\]\[\d+\]\[name\]/)
    end

    context "with a grant the access select can't show" do
      before do
        acl = Hyrax::AccessControlList.new(resource: work)
        acl.grant(:discover).to(Hyrax::Group.new('browsers'))
        acl.save
      end

      it "lists it without a control that would change it" do
        render partial: "hyrax/base/currently_shared", locals: { f: file_set_form }
        page = Capybara::Node::Simple.new(rendered)
        row = page.find('tbody tr', text: 'browsers')

        expect(row).to have_content('Discover')
        expect(row).not_to have_selector('select, input, button')
      end
    end

    context "with a grant the user can't change" do
      before { allow_any_instance_of(Hyrax::EditPermissionsService).to receive(:cannot_edit_permissions?).and_return(true) }

      it "sends it unchanged, so saving the agent's other rows keeps it" do
        render partial: "hyrax/base/currently_shared", locals: { f: file_set_form }
        row = Capybara::Node::Simple.new(rendered).find('tbody tr', text: 'archivists')

        expect(row).not_to have_selector('select, button')
        expect(row).to have_field(type: 'hidden', with: 'read', name: /\[access\]/)
        expect(row).to have_field(type: 'hidden', with: 'archivists', name: /\[name\]/)
      end
    end

    it "hands new grants an index no existing grant uses, hidden ones included" do
      render partial: "hyrax/base/currently_shared", locals: { f: file_set_form }
      page = Capybara::Node::Simple.new(rendered)

      indexes = page.all('[name*="[permissions_attributes]"]', visible: false)
                    .map { |field| field[:name][/\[permissions_attributes\]\[(\d+)\]/, 1].to_i }

      # public (hidden) and archivists
      expect(page.find('#file_permissions')['data-next-index']).to eq '2'
      expect(indexes).to all(be < 2)
    end

    it "gives every row a cell under each column header" do
      render partial: "hyrax/base/currently_shared", locals: { f: file_set_form }
      page = Capybara::Node::Simple.new(rendered)

      expect(page).to have_selector('thead th[scope="col"]', count: 3)
      page.all('tbody tr').each { |row| expect(row).to have_selector('td', count: 3) }
    end
  end
end
