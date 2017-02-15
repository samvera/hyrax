require 'spec_helper'

RSpec.describe Hyrax::Forms::PermissionTemplateForm do
  describe "#update" do
    let(:grant_attributes) { [] }
    let(:input_params) do
      ActionController::Parameters.new(access_grants_attributes: grant_attributes).permit!
    end
    let(:admin_set) { create(:admin_set) }
    let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id) }
    let(:form) { described_class.new(permission_template) }
    subject { form.update(input_params) }
    let(:today) { Time.zone.today }

    it "calls grant_workflow_roles" do
      expect(form).to receive(:grant_workflow_roles)
      subject
    end

    context "with a user manager" do
      let(:grant_attributes) do
        [ActionController::Parameters.new(agent_type: "user",
                                          agent_id: "bob",
                                          access: "manage").permit!]
      end
      it "also adds edit_access to the AdminSet itself" do
        expect { subject }.to change { permission_template.access_grants.count }.by(1)
        expect(admin_set.reload.edit_users).to include 'bob'
      end
    end

    context "with a group manager" do
      let(:grant_attributes) do
        [ActionController::Parameters.new(agent_type: "group",
                                          agent_id: "bob",
                                          access: "manage").permit!]
      end
      it "also adds edit_access to the AdminSet itself" do
        expect { subject }.to change { permission_template.access_grants.count }.by(1)
        expect(admin_set.reload.edit_groups).to include 'bob'
      end
    end

    context "without a manager" do
      let(:grant_attributes) do
        [ActionController::Parameters.new(agent_type: "user",
                                          agent_id: "bob",
                                          access: "view").permit!]
      end
      it "doesn't adds edit_access to the AdminSet itself" do
        expect { subject }.to change { permission_template.access_grants.count }.by(1)
        expect(admin_set.reload.edit_users).to be_empty
      end
    end

    context "with visibility only" do
      let(:input_params) do
        ActionController::Parameters.new(visibility: "open").permit!
      end
      it "updates the visibility" do
        expect { subject }.to change { permission_template.reload.visibility }.from(nil).to('open')
      end
    end

    context "with release 'no delay'" do
      let(:input_params) do
        ActionController::Parameters.new(release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY).permit!
      end
      it "sets release_period=now, release_date=today" do
        expect { subject }.to change { permission_template.reload.release_period }.from(nil).to(Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY)
        expect(permission_template.release_date).to eq(today)
      end
    end

    context "with release 'varies', date specified" do
      let(:input_params) do
        ActionController::Parameters.new(release_period: "", release_varies: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE, release_date: today + 1.year).permit!
      end
      it "sets release_period=before and release_date" do
        expect { subject }.to change { permission_template.reload.release_period }.from(nil).to(Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE)
        expect(permission_template.release_date).to eq(today + 1.year)
      end
    end

    context "with release 'varies', embargo specified" do
      let(:input_params) do
        ActionController::Parameters.new(release_period: "",
                                         release_varies: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO,
                                         release_embargo: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS).permit!
      end
      it "sets release_period to embargo period and release_date to 2 years from now" do
        expect { subject }.to change { permission_template.reload.release_period }.from(nil).to(Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS)
        expect(permission_template.release_date).to eq(today + 2.years)
      end
    end

    context "with release 'fixed', date specified" do
      let(:input_params) do
        ActionController::Parameters.new(release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED,
                                         release_date: today + 1.month).permit!
      end
      it "sets release_period=fixed and release_date" do
        expect { subject }.to change { permission_template.reload.release_period }
          .from(nil)
          .to(Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED)
        expect(permission_template.release_date).to eq(today + 1.month)
      end
    end

    context "with modifying release_period from 'fixed' to 'no_delay'" do
      let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id, release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED, release_date: today + 1.month) }
      let(:input_params) do
        ActionController::Parameters.new(release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY).permit!
      end
      it "sets release_period=now, release_date=today" do
        expect { subject }.to change { permission_template.reload.release_period }
          .from(Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED)
          .to(Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY)
        expect(permission_template.release_date).to eq(today)
      end
    end

    context "with modifying release 'varies' from date specified to embargo specified" do
      let(:permission_template) do
        create(:permission_template,
               admin_set_id: admin_set.id,
               release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE,
               release_date: today + 1.month)
      end
      let(:input_params) do
        ActionController::Parameters.new(release_period: "",
                                         release_varies: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO,
                                         release_embargo: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS).permit!
      end
      it "sets release_period to embargo period, release_date to 2 years from now" do
        expect { subject }.to change { permission_template.reload.release_period }
          .from(Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE)
          .to(Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS)
        expect(permission_template.release_date).to eq(today + 2.years)
      end
    end
  end

  describe "#grant_workflow_roles" do
    subject { form.send(:grant_workflow_roles) }
    let(:admin_set) { create(:admin_set) }
    let(:workflow) { create(:workflow) }
    let(:user) { create(:user) }
    let(:role1) { Sipity::Role.create!(name: 'hello') }
    let(:role2) { Sipity::Role.create!(name: 'goodbye') }

    let(:permission_template) do
      create(:permission_template,
             workflow_id: workflow.id,
             admin_set_id: admin_set.id,
             access_grants_attributes:
               [{ agent_type: 'user',
                  agent_id: user.user_key,
                  access: 'manage' },
                { agent_type: 'group',
                  agent_id: 'librarians',
                  access: 'manage' }])
    end
    let(:form) { described_class.new(permission_template) }
    before do
      permission_template.clear_changes_information
      workflow.workflow_roles.create!([{ role: role1 }, { role: role2 }])
    end

    context "when a new workflow has been chosen" do
      before do
        allow(permission_template).to receive(:previous_changes).and_return("workflow_id" => [nil, workflow.id])
      end

      it "gives the managers workflow roles" do
        expect { subject }.to change { Sipity::WorkflowResponsibility.count }.by(4)
      end
    end

    context "when a new workflow is not changed" do
      it "does nothing" do
        expect { subject }.not_to change { Sipity::WorkflowResponsibility.count }
      end
    end
  end

  describe "#select_release_varies_option" do
    let(:admin_set) { create(:admin_set) }
    let(:form) { described_class.new(permission_template) }
    subject { form.send(:select_release_varies_option, permission_template) }
    let(:today) { Time.zone.today }

    context "with release before date specified" do
      let(:permission_template) do
        create(:permission_template,
               admin_set_id: admin_set.id,
               release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE,
               release_date: today + 1.month)
      end
      it "selects release_varies='before'" do
        expect(form.release_varies).to eq(Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE)
        expect(form.release_embargo).to be_nil
      end
    end

    context "with release embargo specified" do
      let(:permission_template) do
        create(:permission_template,
               admin_set_id: admin_set.id,
               release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR)
      end
      it "selects release_varies='embargo' and value in embargo selectbox" do
        expect(form.release_varies).to eq(Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO)
        expect(form.release_embargo).to eq(Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR)
      end
    end

    context "with release no-delay (now) selected" do
      let(:permission_template) do
        create(:permission_template,
               admin_set_id: admin_set.id,
               release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY)
      end
      it "selects neither varies option, nor embargo" do
        expect(form.release_varies).to be_nil
        expect(form.release_embargo).to be_nil
      end
    end
  end

  describe "#permission_template_update_params" do
    let(:admin_set) { create(:admin_set) }
    let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id) }
    let(:form) { described_class.new(permission_template) }
    subject { form.send(:permission_template_update_params, input_params) }
    let(:today) { Time.zone.today }

    context "with release varies by date selected" do
      let(:input_params) do
        ActionController::Parameters.new(release_period: "",
                                         release_varies: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE,
                                         release_date: today + 1.month).permit!
      end
      it "updates params to release_period=before and keeps date" do
        expect(subject).to eq ActionController::Parameters.new(
          release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE,
          release_date: today + 1.month
        ).permit!
      end
    end

    context "with release varies by embargo selected" do
      let(:input_params) do
        ActionController::Parameters.new(release_period: "",
                                         release_varies: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO,
                                         release_embargo: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR).permit!
      end
      it "updates params to release_period=1yr" do
        expect(subject).to eq ActionController::Parameters.new(
          release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR,
          release_date: nil
        ).permit!
      end
    end

    context "with release no delay (now) selected, after filling out release_date" do
      let(:input_params) do
        ActionController::Parameters.new(release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY,
                                         release_varies: "",
                                         release_embargo: "",
                                         release_date: today + 1.month).permit!
      end
      it "updates params to release_period=1yr" do
        expect(subject).to eq ActionController::Parameters.new(
          release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY,
          release_date: nil
        ).permit!
      end
    end
  end

  describe "#workflows" do
    let(:admin_set) { create(:admin_set) }
    let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id) }
    let(:form) { described_class.new(permission_template) }

    it "returns all of the workflows" do
      expect(Sipity::Workflow).to receive(:all).and_return(:the_workflows)
      expect(form.workflows).to eq(:the_workflows)
    end
  end
end
