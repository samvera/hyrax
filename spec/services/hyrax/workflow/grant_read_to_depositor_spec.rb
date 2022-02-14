# frozen_string_literal: true
require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::Workflow::GrantReadToDepositor do
  subject(:workflow_method) { described_class }
  let(:change_set) { Hyrax::ChangeSet.for(work) }
  let(:depositor) { FactoryBot.create(:user) }
  let(:user) { User.new }

  it_behaves_like 'a Hyrax workflow method'

  describe ".call" do
    context "with no additional viewers" do
      let(:work) { FactoryBot.valkyrie_create(:monograph, depositor: depositor.user_key) }

      it "adds read access" do
        expect { workflow_method.call(target: change_set, comment: "A pleasant read", user: user) }
          .to change { Hyrax::PermissionManager.new(resource: work).read_users.to_a }
          .from(be_empty)
          .to contain_exactly(depositor.user_key)
      end
    end

    context "with an additional viewers" do
      let(:viewer) { FactoryBot.create(:user) }
      let(:work) do
        FactoryBot.valkyrie_create(:monograph,
                                   depositor: depositor.user_key,
                                   read_users: [viewer.user_key])
      end

      it "adds read access" do
        expect { workflow_method.call(target: change_set, comment: "A pleasant read", user: user) }
          .to change { Hyrax::PermissionManager.new(resource: work).read_users.to_a }
          .from(contain_exactly(viewer.user_key))
          .to contain_exactly(viewer.user_key, depositor.user_key)
      end
    end

    context "with attached FileSets", perform_enqueued: [Hyrax::GrantReadToMembersJob] do
      let(:work) do
        FactoryBot.valkyrie_create(:monograph,
                                   :with_member_file_sets,
                                   depositor: depositor.user_key)
      end

      let(:file_set) do
        queries = Hyrax.query_service.custom_queries
        queries.find_child_file_sets(resource: work).first
      end

      it "grants read access" do
        expect { workflow_method.call(target: change_set, comment: "A pleasant read", user: user) }
          .to change { Hyrax::PermissionManager.new(resource: file_set).read_users }
          .from(be_none)
          .to contain_exactly(depositor.user_key)
      end
    end
  end
end
