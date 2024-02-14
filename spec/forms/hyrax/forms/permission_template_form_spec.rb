# frozen_string_literal: true
RSpec.describe Hyrax::Forms::PermissionTemplateForm do
  let(:permission_template) { build(:permission_template) }
  let(:form) { described_class.new(permission_template) }
  let(:today) { Time.zone.today }
  let(:admin_set) { valkyrie_create(:hyrax_admin_set) }

  subject { form }

  it { is_expected.to delegate_method(:available_workflows).to(:model) }
  it { is_expected.to delegate_method(:active_workflow).to(:model) }
  it { is_expected.to delegate_method(:source).to(:model) }
  it { is_expected.to delegate_method(:source_model).to(:model) }
  it { is_expected.to delegate_method(:source_id).to(:model) }
  it { is_expected.to delegate_method(:visibility).to(:model) }

  it 'is expected to delegate method #active_workflow_id to #active_workflow#id' do
    workflow = double(:workflow, id: 1234, active: true)
    expect(permission_template).to receive(:active_workflow).and_return(workflow)
    expect(form.workflow_id).to eq(workflow.id)
  end

  describe 'integration tests' do
    let(:permission_template) { create(:permission_template, with_admin_set: true, with_workflows: true) }

    subject do
      form.update(
        ActionController::Parameters.new(
          access_grants_attributes: [
            ActionController::Parameters.new(agent_type: "user",
                                             agent_id: user.user_key,
                                             access: access_level).permit!
          ]
        ).permit!
      )
    end

    before do
      # Create MANAGING role manually
      Sipity::Role[Hyrax::RoleRegistry::MANAGING]
    end

    def count_template_accesses_for(user, access_level)
      Hyrax::PermissionTemplateAccess.where(
        agent_id: user.user_key,
        access: access_level
      ).count
    end

    def count_workflow_responsibilities_for(user)
      Sipity::WorkflowResponsibility.where(agent: user.to_sipity_agent).count
    end

    it 'starts with no PTAs' do
      expect(permission_template.access_grants).to be_empty
    end

    context 'with manager users' do
      let(:user) { create(:user) }
      let(:access_level) { 'manage' }

      it 'adds the expected permission template accesses and workflow responsibilities' do
        expect { subject }.to change {
          count_template_accesses_for(user, access_level)
        }.from(0).to(1).and change {
          count_workflow_responsibilities_for(user)
        }.from(0).to(6)
      end

      it 'removes workflow responsibilities' do
        subject
        expect do
          form.remove_access!(
            permission_template.access_grants.find_by(agent_id: user.user_key, access: access_level)
          )
        end.to change { count_workflow_responsibilities_for(user) }
          .from(6).to(0)
      end
    end

    context 'with depositor users' do
      let(:user) { create(:user) }
      let(:access_level) { 'deposit' }

      it 'adds the expected permission template accesses and workflow responsibilities' do
        expect { subject }.to change {
          count_template_accesses_for(user, access_level)
        }.from(0).to(1).and change {
          count_workflow_responsibilities_for(user)
        }.from(0).to(2)
      end

      it 'removes workflow responsibilities' do
        subject
        expect do
          form.remove_access!(
            permission_template.access_grants.find_by(agent_id: user.user_key, access: access_level)
          )
        end.to change { count_workflow_responsibilities_for(user) }
          .from(2).to(0)
      end
    end

    context 'with viewer users' do
      let(:user) { create(:user) }
      let(:access_level) { 'view' }

      it 'adds the expected permission template accesses and workflow responsibilities' do
        expect { subject }.to change {
          count_template_accesses_for(user, access_level)
        }.from(0).to(1).and change {
          count_workflow_responsibilities_for(user)
        }.by(0)
      end

      it 'does nothing (yet)' do
        subject
        expect do
          form.remove_access!(
            permission_template.access_grants.find_by(agent_id: user.user_key, access: access_level)
          )
        end.to change { count_workflow_responsibilities_for(user) }
          .by(0)
      end
    end
  end

  describe "#update" do
    subject { form.update(input_params) }

    let(:grant_attributes) { [] }
    let(:input_params) do
      ActionController::Parameters.new(access_grants_attributes: grant_attributes).permit!
    end
    let(:permission_template) { create(:permission_template, source_id: admin_set.id) }

    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    before do
      create(:permission_template_access,
             :manage,
             permission_template: permission_template,
             agent_type: 'user',
             agent_id: user.user_key)
      create(:permission_template_access,
             :manage,
             permission_template: permission_template,
             agent_type: 'group',
             agent_id: 'archivists')
    end

    context "with a user manager" do
      let(:grant_attributes) do
        [ActionController::Parameters.new(agent_type: "user",
                                          agent_id: user2.user_key,
                                          access: "manage").permit!]
      end
      let(:workflow) do
        create(:workflow, permission_template: permission_template)
      end

      before do
        role = Sipity::Role.create(name: 'approving')
        workflow.workflow_roles.create(role: role)
        # We are testing that this workflow role is removed
        Hyrax::Workflow::PermissionGenerator.call(roles: role,
                                                  workflow: workflow,
                                                  agents: user3)
        permission_template.update!(active_workflow: workflow)
      end

      def count_workflow_roles_for(user)
        Hyrax::Workflow::PermissionQuery
          .scope_processing_workflow_roles_for_user_and_workflow(user: user, workflow: workflow)
          .size
      end

      it "adds edit_access to the AdminSet itself and grants workflow roles" do
        expect { subject }.to change { permission_template.access_grants.count }.by(1)
        expect(count_workflow_roles_for(user)).to eq 1
        expect(count_workflow_roles_for(user2)).to eq 1
        expect(count_workflow_roles_for(user3)).to eq 0
        reload = Hyrax.query_service.find_by id: admin_set.id
        expect(reload.edit_users).to match_array [user2.user_key, user.user_key]
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
        reload = Hyrax.query_service.find_by id: admin_set.id
        expect(reload.edit_groups).to match_array ['bob', 'archivists']
      end
    end

    context "without a manager" do
      let(:user_bob) { FactoryBot.create(:user, email: "bob@example.com") }
      let(:grant_attributes) do
        [ActionController::Parameters.new(agent_type: "user",
                                          agent_id: user_bob.user_key,
                                          access: "view").permit!]
      end

      it "doesn't adds edit_access to the AdminSet itself" do
        expect { subject }.to change { permission_template.access_grants.count }.by(1)
        reload = Hyrax.query_service.find_by id: admin_set.id
        expect(reload.edit_users).to match_array [user.user_key] # MANAGE user added in before do
      end
    end

    context "with visibility only" do
      let(:input_params) do
        ActionController::Parameters.new(
          visibility: "open",
          release_period: Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY
        ).permit!
      end

      it "updates the visibility, release_period=now, release_date=today" do
        expect { subject }
          .to change { permission_template.reload.visibility }.from(nil).to('open')
                                                              .and change { permission_template.reload.release_period }.from(nil).to(Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY)
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
               source_id: admin_set.id,
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
               source_id: admin_set.id,
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

    context "for a workflow change" do
      let(:permission_template) { create(:permission_template, source_id: admin_set.id, with_active_workflow: true) }
      let(:new_workflow) { create(:workflow, permission_template: permission_template, active: false) }
      let(:input_params) do
        ActionController::Parameters.new(
          workflow_id: new_workflow.id
        ).permit!
      end

      it "changes the workflow" do
        expect { subject }.to change { permission_template.reload.active_workflow }.to(new_workflow)
        expect(new_workflow.reload).to be_active
      end
    end
  end

  describe "#grant_workflow_roles" do
    subject do
      form.attributes = attributes
      form.send(:grant_workflow_roles)
    end

    let(:attributes) { { workflow_id: workflow.id } }
    let(:workflow) { create(:workflow, permission_template: permission_template, active: true) }
    let(:user) { create(:user) }
    let(:role1) { Sipity::Role.create!(name: 'hello') }
    let(:role2) { Sipity::Role.create!(name: 'goodbye') }

    let(:permission_template) do
      create(:permission_template,
             source_id: admin_set.id,
             access_grants_attributes:
               [{ agent_type: 'user',
                  agent_id: user.user_key,
                  access: 'manage' },
                { agent_type: 'group',
                  agent_id: 'librarians',
                  access: 'manage' }])
    end

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
    let(:permission_template) { create(:permission_template, source_id: admin_set.id) }

    context "validate all release option attribute combinations" do
      let(:visibility) { '' } # default values
      let(:release_date) { nil }
      let(:release_period) { '' }
      let(:release_varies) { nil }
      let(:release_embargo) { nil }
      let(:error_code) { nil }
      let(:attributes) do
        {
          visibility: visibility,
          release_date: release_date,
          release_period: release_period,
          release_varies: release_varies,
          release_embargo: release_embargo
        }
      end
      let(:ac_params) do
        ActionController::Parameters.new(attributes).permit!
      end

      RSpec.shared_examples 'valid attributes' do
        it 'are accepted by #update' do
          expect(form.update(ac_params)).to eq(content_tab: "visibility", updated: true)
        end
      end

      RSpec.shared_examples 'invalid attributes' do
        let(:response) { form.update(ac_params) }

        it 'trigger error from #update' do
          expect(response).to eq(content_tab: "visibility", updated: false, error_code: error_code)
          expect(I18n.t(response[:error_code], scope: 'hyrax.admin.admin_sets.form.permission_update_errors')).not_to include('translation missing')
        end
      end

      describe 'no delay' do
        let(:release_period) { Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY }

        it_behaves_like 'valid attributes'
      end

      describe 'varies, with depositor choice' do
        let(:release_period) { '' }
        let(:release_varies) { '' }

        it_behaves_like 'valid attributes'
      end

      describe 'varies, with date selected' do
        let(:release_date) { Time.zone.today + 2.months }
        let(:release_varies) { Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE }

        it_behaves_like 'valid attributes'
      end

      describe 'varies, with embargo selected' do
        let(:release_varies) { Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO }
        let(:release_embargo) { Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS }

        it_behaves_like 'valid attributes'
      end

      describe 'fixed, with date selected' do
        let(:release_date) { Time.zone.today + 2.months }
        let(:release_period) { Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED }

        it_behaves_like 'valid attributes'
      end

      describe 'varies, but no subsequent options' do
        let(:release_period) { nil }
        let(:error_code) { 'nothing' }

        it_behaves_like 'invalid attributes'
      end

      describe 'varies, with date option but no date' do
        let(:release_varies) { Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE }
        let(:release_date) { '' }
        let(:error_code) { 'no_date' }

        it_behaves_like 'invalid attributes'
      end

      describe 'varies, with embargo option but no period' do
        let(:release_varies) { Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO }
        let(:release_embargo) { '' }
        let(:error_code) { 'no_embargo' }

        it_behaves_like 'invalid attributes'
      end

      describe 'fixed, with no date selected' do
        let(:release_period) { Hyrax::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED }
        let(:release_date) { '' }
        let(:error_code) { 'no_date' }

        it_behaves_like 'invalid attributes'
      end
    end
  end

  describe "#select_release_varies_option" do
    subject { form.send(:select_release_varies_option, permission_template) }

    context "with release before date specified" do
      let(:permission_template) do
        create(:permission_template,
               source_id: admin_set.id,
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
               source_id: admin_set.id,
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
               source_id: admin_set.id,
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
    let(:permission_template) { create(:permission_template, source_id: admin_set.id) }

    subject do
      form.attributes = input_params
      form.send(:permission_template_update_params)
    end

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

    context "update params for workflow role with no :release_varies and :release_embargo keys" do
      let(:user_bob) { FactoryBot.create(:user, email: "bob@example.com") }
      let(:input_params) do
        ActionController::Parameters.new(agent_type: "user",
                                         agent_id: user_bob.user_key,
                                         access: "view").permit!
      end

      it "should not change" do
        expect(subject).to eq ActionController::Parameters.new(
          agent_type: "user",
          agent_id: user_bob.user_key,
          access: "view"
        ).permit!
      end
    end
  end
end
