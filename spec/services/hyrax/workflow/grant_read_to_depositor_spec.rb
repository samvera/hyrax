# frozen_string_literal: true
require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::Workflow::GrantReadToDepositor do
  let(:depositor) { create(:user) }
  let(:user) { User.new }

  let(:workflow_method) { described_class }

  it_behaves_like 'a Hyrax workflow method'

  describe ".call" do
    subject do
      described_class.call(target: work,
                           comment: "A pleasant read",
                           user: user)
    end

    context "with no additional viewers" do
      let(:work) { create(:work_without_access, depositor: depositor.user_key) }

      it "adds read access" do
        expect { subject }.to change { work.read_users }.from([]).to([depositor.user_key])
        expect(work).to be_valid
      end
    end

    context "with an additional viewers" do
      let(:viewer) { create(:user) }
      let(:work) { create(:work_without_access, depositor: depositor.user_key, read_users: [viewer.user_key]) }

      it "adds read access" do
        expect { subject }.to change { work.read_users }.from([viewer.user_key]).to([viewer.user_key, depositor.user_key])
        expect(work).to be_valid
      end
    end

    context "with attached FileSets", perform_enqueued: [Hyrax::GrantReadToMembersJob] do
      let(:work) { create(:work_with_one_file, user: depositor) }
      let(:file_set) { work.members.first }

      it "grants read access" do
        # We need to reload, because this work happens in a background job
        expect { subject }.to change { file_set.reload.read_users }.from([]).to([depositor.user_key])
        expect(work).to be_valid
      end
    end
  end
end
