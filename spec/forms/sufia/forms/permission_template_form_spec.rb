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
        ActionController::Parameters.new(release_period: "now").permit!
      end
      it "sets release_period=now" do
        expect { subject }.to change { permission_template.reload.release_period }.from(nil).to('now')
        expect(permission_template.release_date).to be_nil
      end
    end

    context "with release 'varies', date specified" do
      let(:input_params) do
        ActionController::Parameters.new(release_period: "", release_varies: "before", release_date: "2017-01-01").permit!
      end
      it "sets release_period=before and release_date" do
        expect { subject }.to change { permission_template.reload.release_period }.from(nil).to('before')
        expect(permission_template.release_date).to eq(Date.parse("2017-01-01"))
      end
    end

    context "with release 'varies', embargo specified" do
      let(:input_params) do
        ActionController::Parameters.new(release_period: "", release_varies: "embargo", release_embargo: "2yrs").permit!
      end
      it "sets release_period to embargo period" do
        expect { subject }.to change { permission_template.reload.release_period }.from(nil).to('2yrs')
        expect(permission_template.release_date).to be_nil
      end
    end

    context "with release 'fixed', date specified" do
      let(:input_params) do
        ActionController::Parameters.new(release_period: "fixed", release_date: "2017-01-01").permit!
      end
      it "sets release_period=fixed and release_date" do
        expect { subject }.to change { permission_template.reload.release_period }.from(nil).to('fixed')
        expect(permission_template.release_date).to eq(Date.parse("2017-01-01"))
      end
    end

    context "with modifying release_period from 'fixed' to 'no_delay'" do
      let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id, release_period: "fixed", release_date: "2017-01-01") }
      let(:input_params) do
        ActionController::Parameters.new(release_period: "now").permit!
      end
      it "sets release_period=now, release_date=nil" do
        expect { subject }.to change { permission_template.reload.release_period }.from('fixed').to('now')
        expect(permission_template.release_date).to be_nil
      end
    end

    context "with modifying release 'varies' from date specified to embargo specified" do
      let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id, release_period: "before", release_date: "2017-01-01") }
      let(:input_params) do
        ActionController::Parameters.new(release_period: "", release_varies: "embargo", release_embargo: "2yrs").permit!
      end
      it "sets release_period to embargo period, release_date=nil" do
        expect { subject }.to change { permission_template.reload.release_period }.from('before').to('2yrs')
        expect(permission_template.release_date).to be_nil
      end
    end
  end

  describe "#select_release_varies_option" do
    let(:admin_set) { create(:admin_set) }
    let(:form) { described_class.new(permission_template) }
    subject { form.send(:select_release_varies_option, permission_template) }

    context "with release before date specified" do
      let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id, release_period: "before", release_date: "2017-01-01") }
      it "selects release_varies='before'" do
        expect(form.release_varies).to eq('before')
        expect(form.release_embargo).to be_nil
      end
    end

    context "with release embargo specified" do
      let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id, release_period: "1yr") }
      it "selects release_varies='embargo' and value in embargo selectbox" do
        expect(form.release_varies).to eq('embargo')
        expect(form.release_embargo).to eq('1yr')
      end
    end

    context "with release no-delay (now) selected" do
      let(:permission_template) { create(:permission_template, admin_set_id: admin_set.id, release_period: "now") }
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

    context "with release varies by date selected" do
      let(:input_params) do
        ActionController::Parameters.new(release_period: "", release_varies: "before", release_date: "2017-01-01").permit!
      end
      it "updates params to release_period=before and keeps date" do
        expect { subject }.to change { input_params[:release_period] }.from("").to("before")
        expect(input_params[:release_date]).to eq("2017-01-01")
        expect(input_params[:release_varies]).to be_nil
        expect(input_params[:release_embargo]).to be_nil
      end
    end

    context "with release varies by embargo selected" do
      let(:input_params) do
        ActionController::Parameters.new(release_period: "", release_varies: "embargo", release_embargo: "1yr").permit!
      end
      it "updates params to release_period=1yr" do
        expect { subject }.to change { input_params[:release_period] }.from("").to("1yr")
        expect(input_params[:release_date]).to be_nil
        expect(input_params[:release_varies]).to be_nil
        expect(input_params[:release_embargo]).to be_nil
      end
    end

    context "with release no delay (now) selected, after filling out release_date" do
      let(:input_params) do
        ActionController::Parameters.new(release_period: "now", release_varies: "", release_embargo: "", release_date: "2017-01-01").permit!
      end
      it "updates params to release_period=1yr" do
        expect { subject }.to change { input_params[:release_date] }.from("2017-01-01").to(nil)
        expect(input_params[:release_period]).to eq("now")
        expect(input_params[:release_varies]).to be_nil
        expect(input_params[:release_embargo]).to be_nil
      end
    end
  end
end
