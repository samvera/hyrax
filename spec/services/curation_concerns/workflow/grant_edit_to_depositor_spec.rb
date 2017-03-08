require 'spec_helper'

RSpec.describe CurationConcerns::Workflow::GrantEditToDepositor do
  let(:depositor) { create(:user) }
  let(:user) { User.new }

  describe ".call" do
    subject do
      described_class.call(target: work,
                           comment: "A pleasant read",
                           user: user)
    end

    context "with no additional editors" do
      let(:work) { create(:work_without_access, depositor: depositor.user_key) }
      it "adds edit access" do
        expect { subject }.to change { work.edit_users }.from([]).to([depositor.user_key])
        expect(work).to be_valid
      end
    end

    context "with an additional editor" do
      let(:editor) { create(:user) }
      let(:work) { create(:work_without_access, depositor: depositor.user_key, edit_users: [editor.user_key]) }
      it "adds edit access" do
        expect { subject }.to change { work.edit_users }.from([editor.user_key]).to([editor.user_key, depositor.user_key])
        expect(work).to be_valid
      end
    end
  end
end
