# frozen_string_literal: true
RSpec.describe 'hyrax/dashboard/collections/_form_share_table.html.erb', type: :view do
  let(:template) { stub_model(Hyrax::PermissionTemplate) }
  let(:user) { create(:user) }
  let(:access_grant) { stub_model(Hyrax::PermissionTemplateAccess) }
  let(:collection) { stub_model(Collection) }
  let(:collection_type) { stub_model(Hyrax::CollectionType, share_applies_to_new_works?: false) }
  let(:pt_form) do
    instance_double(Hyrax::Forms::PermissionTemplateForm,
                    model_name: template.model_name,
                    to_key: template.to_key,
                    access_grants: [access_grant])
  end

  before do
    assign(:collection, collection)
    allow(view).to receive(:collection_type).and_return(collection_type)
    @form = instance_double(Hyrax::Forms::CollectionForm,
                            to_model: stub_model(Collection),
                            permission_template: pt_form)
    # A collection_type helper method normally provided by the controller
    allow(view).to receive(:collection_type).and_return(collection_type)
    # Ignore the delete button link
    allow(view).to receive(:admin_permission_template_access_path).and_return("/admin/permission_template_accesses/123")
  end

  describe "Manager shares table" do
    before do
      render 'form_share_table', access: "managers", filter: :manage?
    end

    context "managers exist" do
      let(:access_grant) do
        stub_model(Hyrax::PermissionTemplateAccess,
                   agent_type: 'user',
                   agent_id: user.user_key,
                   access: 'manage')
      end

      it "lists the managers in the table" do
        expect(rendered).to have_selector("h3", text: "Managers")
        expect(rendered).to have_selector("table tbody", text: user.user_key)
      end
    end
    context "no managers exist" do
      let(:access_grant) { stub_model(Hyrax::PermissionTemplateAccess) }

      it "displays a message and no table" do
        expect(rendered).to have_selector("h3", text: "Managers")
        expect(rendered).not_to have_selector("table")
        expect(rendered).to have_content("No managers have been added to this collection.")
      end
    end
  end

  describe "Viewer shares table" do
    before do
      render 'form_share_table', access: "viewers", filter: :view?
    end

    context "viewers exist" do
      let(:access_grant) do
        stub_model(Hyrax::PermissionTemplateAccess,
                   agent_type: 'user',
                   agent_id: user.user_key,
                   access: 'view')
      end

      it "lists the viewers in the table" do
        expect(rendered).to have_selector("h3", text: "Viewers")
        expect(rendered).to have_selector("table tbody", text: user.user_key)
      end
    end
    context "no viewers exist" do
      let(:access_grant) { stub_model(Hyrax::PermissionTemplateAccess) }

      it "displays a message and no table" do
        expect(rendered).to have_selector("h3", text: "Viewers")
        expect(rendered).not_to have_selector("table")
        expect(rendered).to have_content("No viewers have been added to this collection.")
      end
    end
  end

  describe "Depositor shares table" do
    before do
      render 'form_share_table', access: "depositors", filter: :deposit?
    end

    context "depositors exist" do
      let(:access_grant) do
        stub_model(Hyrax::PermissionTemplateAccess,
                   agent_type: 'user',
                   agent_id: user.user_key,
                   access: 'deposit')
      end

      it "lists the depositors in the table" do
        expect(rendered).to have_selector("h3", text: "Depositors")
        expect(rendered).to have_selector("table tbody", text: user.user_key)
      end
    end
    context "no depositors exist" do
      let(:access_grant) { stub_model(Hyrax::PermissionTemplateAccess) }

      it "displays a message and no table" do
        expect(rendered).to have_selector("h3", text: "Depositors")
        expect(rendered).not_to have_selector("table")
        expect(rendered).to have_content("No depositors have been added to this collection.")
      end
    end
  end
end
