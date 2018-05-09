require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::Workflow::RevokeEditFromDepositor do
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

    context "with no additional editors" do
      let(:work) { create(:work_without_access, depositor: depositor.user_key, edit_users: [depositor.user_key]) }

      it "removes edit access" do
        expect { subject }.to change { work.edit_users }.from([depositor.user_key]).to([])
        expect(work).to be_valid
      end
    end

    context "with an additional editor" do
      let(:editor) { create(:user) }
      let(:work) { create(:work_without_access, depositor: depositor.user_key, edit_users: [depositor.user_key, editor.user_key]) }

      it "removes edit access" do
        expect { subject }.to change { work.edit_users }.from([depositor.user_key, editor.user_key]).to([editor.user_key])
        expect(work).to be_valid
      end
    end

    context "with attached FileSets", perform_enqueued: [Hyrax::RevokeEditFromMembersJob] do
      let(:work) { create(:work_with_one_file, user: depositor) }
      let(:file_set) { work.members.first }

      it "removes edit access" do
        # We need to reload, because this work happens in a background job
        expect { subject }.to change { file_set.reload.edit_users }.from([depositor.user_key]).to([])
        expect(work).to be_valid
      end
    end
  end
end
