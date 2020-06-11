# frozen_string_literal: true
RSpec.describe 'hyrax/admin/admin_sets/_form_participant_table.html.erb', type: :view do
  let(:template) { stub_model(Hyrax::PermissionTemplate) }
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let(:access_grants) { [stub_model(Hyrax::PermissionTemplateAccess)] }
  let(:pt_form) do
    instance_double(Hyrax::Forms::PermissionTemplateForm,
                    model_name: template.model_name,
                    to_key: template.to_key,
                    access_grants: access_grants)
  end

  before do
    @form = instance_double(Hyrax::Forms::AdminSetForm,
                            to_model: stub_model(AdminSet),
                            permission_template: pt_form)
    # Ignore the delete button link
    allow(view).to receive(:admin_permission_template_access_path).and_return("/admin/permission_template_accesses/123")
  end

  describe "Manager participants table" do
    before do
      render 'form_participant_table', access: "managers", filter: :manage?
    end

    context "managers exist" do
      let(:access_grants) do
        [stub_model(Hyrax::PermissionTemplateAccess,
                    agent_type: 'user',
                    agent_id: user.user_key,
                    access: 'manage'),
         stub_model(Hyrax::PermissionTemplateAccess,
                    agent_type: 'group',
                    agent_id: Ability.admin_group_name,
                    access: 'manage')]
      end

      it "lists the managers in the table" do
        expect(rendered).to have_selector("h3", text: "Managers")
        expect(rendered).to have_selector("table tbody", text: user.user_key)
        expect(rendered).to have_selector("table tbody", text: 'Repository Administrators')
        expect(rendered).to have_button(class: 'btn-danger', disabled: true,
                                        title: 'The repository administrators group cannot be removed')
      end
    end
    context "no managers exist" do
      let(:access_grants) { [stub_model(Hyrax::PermissionTemplateAccess)] }

      it "displays a message and no table" do
        expect(rendered).to have_selector("h3", text: "Managers")
        expect(rendered).not_to have_selector("table")
        expect(rendered).to have_content("No managers have been added to this administrative set.")
      end
    end
  end

  describe "Viewer participants table" do
    before do
      render 'form_participant_table', access: "viewers", filter: :view?
    end

    context "viewers exist" do
      let(:access_grants) do
        [stub_model(Hyrax::PermissionTemplateAccess,
                    agent_type: 'user',
                    agent_id: user.user_key,
                    access: 'view'),
         stub_model(Hyrax::PermissionTemplateAccess,
                    agent_type: 'group',
                    agent_id: Ability.admin_group_name,
                    access: 'view')]
      end

      it "lists the viewers in the table" do
        expect(rendered).to have_selector("h3", text: "Viewers")
        expect(rendered).to have_selector("table tbody", text: user.user_key)
        expect(rendered).to have_selector("table tbody", text: 'Repository Administrators')
        expect(rendered).not_to have_button(class: 'btn-danger', disabled: true,
                                            title: 'The repository administrators group cannot be removed')
      end
    end
    context "no viewers exist" do
      let(:access_grants) { [stub_model(Hyrax::PermissionTemplateAccess)] }

      it "displays a message and no table" do
        expect(rendered).to have_selector("h3", text: "Viewers")
        expect(rendered).not_to have_selector("table")
        expect(rendered).to have_content("No viewers have been added to this administrative set.")
      end
    end
  end

  describe "Depositor participants table" do
    before do
      render 'form_participant_table', access: "depositors", filter: :deposit?
    end

    context "depositors exist" do
      let(:access_grants) do
        [stub_model(Hyrax::PermissionTemplateAccess,
                    agent_type: 'user',
                    agent_id: user.user_key,
                    access: 'deposit'),
         stub_model(Hyrax::PermissionTemplateAccess,
                    agent_type: 'group',
                    agent_id: Ability.admin_group_name,
                    access: 'deposit')]
      end

      it "lists the depositors in the table" do
        expect(rendered).to have_selector("h3", text: "Depositors")
        expect(rendered).to have_selector("table tbody", text: user.user_key)
        expect(rendered).to have_selector("table tbody", text: 'Repository Administrators')
        expect(rendered).not_to have_button(class: 'btn-danger', disabled: true,
                                            title: 'The repository administrators group cannot be removed')
      end
    end
    context "no depositors exist" do
      let(:access_grants) { [stub_model(Hyrax::PermissionTemplateAccess)] }

      it "displays a message and no table" do
        expect(rendered).to have_selector("h3", text: "Depositors")
        expect(rendered).not_to have_selector("table")
        expect(rendered).to have_content("No depositors have been added to this administrative set.")
      end
    end
  end
end
