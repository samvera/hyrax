require 'spec_helper'

RSpec.describe CurationConcerns::Workflow::GrantEditToDepositor do
  let(:depositor) { create(:user) }
  let(:work) { create(:work_without_access, depositor: depositor.user_key) }
  let(:user) { User.new }

  describe ".call" do
    subject do
      described_class.call(target: work,
                           comment: "A pleasant read",
                           user: user)
    end

    it "adds edit access " do
      expect { subject }.to change { work.edit_users }.from([]).to([depositor.user_key])
      expect(work).to be_valid
    end
  end
end
