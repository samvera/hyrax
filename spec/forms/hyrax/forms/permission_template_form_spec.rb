require 'spec_helper'

RSpec.describe Hyrax::Forms::PermissionTemplateForm do
  let(:permission_template) { build(:permission_template) }
  let(:form) { described_class.new(permission_template) }
  subject { form }
  it { is_expected.to delegate_method(:available_workflows).to(:model) }
  it { is_expected.to delegate_method(:active_workflow).to(:model) }
  it { is_expected.to delegate_method(:admin_set).to(:model) }
  it { is_expected.to delegate_method(:visibility).to(:model) }

  it 'is expected to delegate method #active_workflow_id to #active_workflow#id' do
    workflow = double(:workflow, id: 1234, active: true)
    expect(permission_template).to receive(:active_workflow).and_return(workflow)
    expect(form.workflow_id).to eq(workflow.id)
  end

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
        ActionController::Parameters.new(
          visibility: "open",
          release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY
        ).permit!
      end
      it "updates the visibility" do
        expect { subject }.to change { permission_template.reload.visibility }.from(nil).to('open')
      end
    end

    context "with release 'no delay'" do
      let(:input_params) do
        ActionController::Parameters.new(
          visibility: "open",
          release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY
        ).permit!
      end
      it "sets release_period=now, release_date=today" do
        expect { subject }.to change { permission_template.reload.release_period }.from(nil).to(Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY)
        expect(permission_template.release_date).to eq(today)
      end
    end

    context "with release 'varies', date specified" do
      let(:input_params) do
        ActionController::Parameters.new(
          visibility: "open",
          release_period: "",
          release_varies: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE,
          release_date: today + 1.year
        ).permit!
      end
      it "sets release_period=before and release_date" do
        expect { subject }.to change { permission_template.reload.release_period }.from(nil).to(Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE)
        expect(permission_template.release_date).to eq(today + 1.year)
      end
    end

    context "with release 'varies', embargo specified" do
      let(:input_params) do
        ActionController::Parameters.new(
          visibility: "open",
          release_period: "",
          release_varies: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO,
          release_embargo: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS
        ).permit!
      end
      it "sets release_period to embargo period and release_date to 2 years from now" do
        expect { subject }.to change { permission_template.reload.release_period }.from(nil).to(Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS)
        expect(permission_template.release_date).to eq(today + 2.years)
      end
    end

    context "with release 'fixed', date specified" do
      let(:input_params) do
        ActionController::Parameters.new(
          visibility: "open",
          release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED,
          release_date: today + 1.month
        ).permit!
      end
      it "sets release_period=fixed and release_date" do
        expect { subject }.to change { permission_template.reload.release_period }
          .from(nil)
          .to(Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED)
        expect(permission_template.release_date).to eq(today + 1.month)
      end
    end

    context "with modifying release_period from 'fixed' to 'no_delay'" do
      let(:permission_template) do
        create(:permission_template,
               admin_set_id: admin_set.id,
               visibility: "open",
               release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED,
               release_date: today + 1.month)
      end
      let(:input_params) do
        ActionController::Parameters.new(
          visibility: "open",
          release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY
        ).permit!
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
               visibility: "open",
               release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE,
               release_date: today + 1.month)
      end
      let(:input_params) do
        ActionController::Parameters.new(
          visibility: "open",
          release_period: "",
          release_varies: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO,
          release_embargo: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS
        ).permit!
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
    subject { form.send(:grant_workflow_roles, attributes) }
    let(:attributes) { { workflow_id: workflow.id } }
    let(:admin_set) { create(:admin_set) }
    let(:workflow) { create(:workflow, permission_template: permission_template, active: true) }
    let(:user) { create(:user) }
    let(:role1) { Sipity::Role.create!(name: 'hello') }
    let(:role2) { Sipity::Role.create!(name: 'goodbye') }

    let(:permission_template) do
      create(:permission_template,
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
      it "gives the managers workflow roles" do
        expect { subject }.to change { Sipity::WorkflowResponsibility.count }.by(4)
      end
    end

    context "when a workflow is not changed" do
      it "does nothing" do
        subject # Setting up the subject to verify that when we call it again things don't change
        expect { subject }.not_to change { Sipity::WorkflowResponsibility.count }
      end
    end
  end

  describe "#validate_visibility_combinations" do
    let(:admin_set) { create(:admin_set) }
    let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id) }
    let(:form) { described_class.new(permission_template) }

    context "validate all release option attribute combinations" do
      def self.expect_attributes_to_be_valid(attributes = {})
        it "will be valid? for #{attributes.inspect}" do
          attributes = ActionController::Parameters.new(**attributes).permit!
          expect(form.update(attributes)).to eq(content_tab: "visibility", updated: true)
        end
      end

      def self.expect_attributes_not_to_be_valid(attributes = {})
        it "will not be valid? for #{attributes.inspect}" do
          attributes = ActionController::Parameters.new(**attributes).permit!
          subject = form.update(attributes)
          expect(subject).to include(content_tab: "visibility", updated: false)
          expect(I18n.t(subject[:error_code], scope: 'hyrax.admin.admin_sets.form.permission_update_errors')).not_to include('translation missing')
        end
      end

      # no delay
      expect_attributes_to_be_valid(
        visibility: '',
        release_date: Time.zone.today,
        release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY,
        release_varies: nil,
        release_embargo: nil
      )
      # varies, with date selected
      expect_attributes_to_be_valid(
        visibility: '',
        release_date: Time.zone.today + 2.months,
        release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE,
        release_varies: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE,
        release_embargo: nil
      )
      # varies, with embargo selected
      expect_attributes_to_be_valid(
        visibility: '',
        release_date: Time.zone.today + 2.years,
        release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS,
        release_varies: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO,
        release_embargo: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS
      )
      # fixed, with date selected
      expect_attributes_to_be_valid(
        visibility: '',
        release_date: Time.zone.today + 2.months,
        release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED,
        release_varies: nil,
        release_embargo: nil
      )
      # varies, but no subsequent options
      expect_attributes_not_to_be_valid(
        visibility: '',
        release_date: nil,
        release_period: '',
        release_varies: nil,
        release_embargo: nil
      )
      # varies, with date option but no date
      expect_attributes_not_to_be_valid(
        visibility: '',
        release_date: nil,
        release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE,
        release_varies: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE,
        release_embargo: nil
      )
      # varies, with embargo option but no period
      expect_attributes_not_to_be_valid(
        visibility: '',
        release_date: nil,
        release_period: '',
        release_varies: nil,
        release_embargo: nil
      )
      # fixed, with no date selected
      expect_attributes_not_to_be_valid(
        visibility: '',
        release_date: nil,
        release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED,
        release_varies: nil,
        release_embargo: nil
      )
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
               visibility: '',
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
               visibility: '',
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
               visibility: '',
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
        ActionController::Parameters.new(visibility: '',
                                         release_period: "",
                                         release_varies: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE,
                                         release_date: today + 1.month).permit!
      end
      it "updates params to release_period=before and keeps date" do
        expect(subject).to eq ActionController::Parameters.new(
          visibility: '',
          release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE,
          release_date: today + 1.month
        ).permit!
      end
    end

    context "with release varies by embargo selected" do
      let(:input_params) do
        ActionController::Parameters.new(visibility: '',
                                         release_period: "",
                                         release_varies: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO,
                                         release_embargo: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR).permit!
      end
      it "updates params to release_period=1yr" do
        expect(subject).to eq ActionController::Parameters.new(
          visibility: '',
          release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR,
          release_date: nil
        ).permit!
      end
    end

    context "with release no delay (now) selected, after filling out release_date" do
      let(:input_params) do
        ActionController::Parameters.new(visibility: '',
                                         release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY,
                                         release_varies: "",
                                         release_embargo: "",
                                         release_date: today + 1.month).permit!
      end
      it "updates params to release_period=1yr" do
        expect(subject).to eq ActionController::Parameters.new(
          visibility: '',
          release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY,
          release_date: nil
        ).permit!
      end
    end
  end
end
