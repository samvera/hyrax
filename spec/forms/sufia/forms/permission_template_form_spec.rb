require 'spec_helper'

RSpec.describe Sufia::Forms::PermissionTemplateForm do
  describe "#update" do
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
        ActionController::Parameters.new(visibility: "open").permit!
      end
      it "updates the visibility" do
        expect { subject }.to change { permission_template.reload.visibility }.from(nil).to('open')
      end
    end

    context "with release 'no delay'" do
      let(:input_params) do
        ActionController::Parameters.new(release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY).permit!
      end
      it "sets release_period=now, release_date=today" do
        expect { subject }.to change { permission_template.reload.release_period }.from(nil).to(Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY)
        expect(permission_template.release_date).to eq(today)
      end
    end

    context "with release 'varies', date specified" do
      let(:input_params) do
        ActionController::Parameters.new(release_period: "", release_varies: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE, release_date: today + 1.year).permit!
      end
      it "sets release_period=before and release_date" do
        expect { subject }.to change { permission_template.reload.release_period }.from(nil).to(Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE)
        expect(permission_template.release_date).to eq(today + 1.year)
      end
    end

    context "with release 'varies', embargo specified" do
      let(:input_params) do
        ActionController::Parameters.new(release_period: "", release_varies: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO, release_embargo: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS).permit!
      end
      it "sets release_period to embargo period and release_date to 2 years from now" do
        expect { subject }.to change { permission_template.reload.release_period }.from(nil).to(Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS)
        expect(permission_template.release_date).to eq(today + 2.years)
      end
    end

    context "with release 'fixed', date specified" do
      let(:input_params) do
        ActionController::Parameters.new(release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED, release_date: today + 1.month).permit!
      end
      it "sets release_period=fixed and release_date" do
        expect { subject }.to change { permission_template.reload.release_period }.from(nil).to(Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED)
        expect(permission_template.release_date).to eq(today + 1.month)
      end
    end

    context "with modifying release_period from 'fixed' to 'no_delay'" do
      let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id, release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED, release_date: today + 1.month) }
      let(:input_params) do
        ActionController::Parameters.new(release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY).permit!
      end
      it "sets release_period=now, release_date=today" do
        expect { subject }.to change { permission_template.reload.release_period }.from(Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_FIXED).to(Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY)
        expect(permission_template.release_date).to eq(today)
      end
    end

    context "with modifying release 'varies' from date specified to embargo specified" do
      let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id, release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE, release_date: today + 1.month) }
      let(:input_params) do
        ActionController::Parameters.new(release_period: "", release_varies: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO, release_embargo: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS).permit!
      end
      it "sets release_period to embargo period, release_date to 2 years from now" do
        expect { subject }.to change { permission_template.reload.release_period }.from(Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE).to(Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_2_YEARS)
        expect(permission_template.release_date).to eq(today + 2.years)
      end
    end
  end

  describe "#select_release_varies_option" do
    let(:admin_set) { create(:admin_set) }
    let(:form) { described_class.new(permission_template) }
    subject { form.send(:select_release_varies_option, permission_template) }
    let(:today) { Time.zone.today }

    context "with release before date specified" do
      let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id, release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE, release_date: today + 1.month) }
      it "selects release_varies='before'" do
        expect(form.release_varies).to eq(Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE)
        expect(form.release_embargo).to be_nil
      end
    end

    context "with release embargo specified" do
      let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id, release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR) }
      it "selects release_varies='embargo' and value in embargo selectbox" do
        expect(form.release_varies).to eq(Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO)
        expect(form.release_embargo).to eq(Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR)
      end
    end

    context "with release no-delay (now) selected" do
      let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id, release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY) }
      it "selects neither varies option, nor embargo" do
        expect(form.release_varies).to be_nil
        expect(form.release_embargo).to be_nil
      end
    end
  end

  describe "#update_release_attributes" do
    let(:admin_set) { create(:admin_set) }
    let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id) }
    let(:form) { described_class.new(permission_template) }
    subject { form.send(:update_release_attributes, input_params) }
    let(:today) { Time.zone.today }

    context "with release varies by date selected" do
      let(:input_params) do
        ActionController::Parameters.new(release_period: "", release_varies: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE, release_date: today + 1.month).permit!
      end
      it "updates params to release_period=before and keeps date" do
        expect { subject }.to change { input_params[:release_period] }.from("").to(Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_BEFORE_DATE)
        expect(input_params[:release_date]).to eq(today + 1.month)
        expect(input_params[:release_varies]).to be_nil
        expect(input_params[:release_embargo]).to be_nil
      end
    end

    context "with release varies by embargo selected" do
      let(:input_params) do
        ActionController::Parameters.new(release_period: "", release_varies: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_EMBARGO, release_embargo: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR).permit!
      end
      it "updates params to release_period=1yr" do
        expect { subject }.to change { input_params[:release_period] }.from("").to(Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_1_YEAR)
        expect(input_params[:release_date]).to be_nil
        expect(input_params[:release_varies]).to be_nil
        expect(input_params[:release_embargo]).to be_nil
      end
    end

    context "with release no delay (now) selected, after filling out release_date" do
      let(:input_params) do
        ActionController::Parameters.new(release_period: Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY, release_varies: "", release_embargo: "", release_date: today + 1.month).permit!
      end
      it "updates params to release_period=1yr" do
        expect { subject }.to change { input_params[:release_date] }.from(today + 1.month).to(nil)
        expect(input_params[:release_period]).to eq(Sufia::PermissionTemplate::RELEASE_TEXT_VALUE_NO_DELAY)
        expect(input_params[:release_varies]).to be_nil
        expect(input_params[:release_embargo]).to be_nil
      end
    end
  end
end
