# frozen_string_literal: true
require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::Workflow::GrantReadToDepositor do
  let(:depositor) { FactoryBot.create(:user) }
  let(:user) { User.new }

  subject(:workflow_method) { described_class }

  it_behaves_like 'a Hyrax workflow method'

  describe ".call" do
    context "with no additional viewers" do
      let(:work) { FactoryBot.create(:work_without_access, depositor: depositor.user_key) }

      it "adds read access" do
        expect { workflow_method.call(target: work, comment: "A pleasant read", user: user) }
          .to change { work.read_users }
          .from(be_empty)
          .to contain_exactly(depositor.user_key)
      end
    end

    context "with an additional viewers" do
      let(:viewer) { FactoryBot.create(:user) }
      let(:work) { FactoryBot.create(:work_without_access, depositor: depositor.user_key, read_users: [viewer.user_key]) }

      it "adds read access" do
        expect { workflow_method.call(target: work, comment: "A pleasant read", user: user) }
          .to change { work.read_users }
          .from(contain_exactly(viewer.user_key))
          .to contain_exactly(viewer.user_key, depositor.user_key)
      end
    end

    context "with attached FileSets", perform_enqueued: [Hyrax::GrantReadToMembersJob] do
      let(:work) { FactoryBot.create(:work_with_one_file, user: depositor) }
      let(:file_set) { work.members.first }

      it "grants read access" do
        expect { workflow_method.call(target: work, comment: "A pleasant read", user: user) }
          .to change { file_set.reload.read_users }
          .from(be_empty)
          .to contain_exactly(depositor.user_key)
      end
    end
  end
end
