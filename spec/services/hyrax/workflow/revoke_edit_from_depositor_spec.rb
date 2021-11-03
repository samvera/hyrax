# frozen_string_literal: true
require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::Workflow::RevokeEditFromDepositor do
  subject(:workflow_method) { described_class }
  let(:change_set) { Hyrax::ChangeSet.for(work) }
  let(:depositor) { FactoryBot.create(:user) }
  let(:editors) { [depositor.user_key] }
  let(:user) { User.new }

  let(:work) do
    FactoryBot.valkyrie_create(:monograph,
                               depositor: depositor.user_key,
                               edit_users: editors)
  end

  it_behaves_like 'a Hyrax workflow method'

  describe ".call" do
    context "with no additional editors" do
      it "removes edit access" do
        expect { workflow_method.call(target: change_set, comment: "A pleasant read", user: user) }
          .to change { Hyrax::PermissionManager.new(resource: work).edit_users }
          .from(contain_exactly(depositor.user_key))
          .to be_none
      end
    end

    context "with an additional editor" do
      let(:editor) { FactoryBot.create(:user) }
      let(:editors) { [depositor, editor].map(&:user_key) }

      it "removes edit access" do
        expect { workflow_method.call(target: change_set, comment: "A pleasant read", user: user) }
          .to change { Hyrax::PermissionManager.new(resource: work).edit_users }
          .from(contain_exactly(*editors))
          .to contain_exactly(editor.user_key)
      end
    end

    context "with attached FileSets", perform_enqueued: [Hyrax::RevokeEditFromMembersJob] do
      let(:work) do
        FactoryBot.valkyrie_create(:monograph,
                                   members: [file_set],
                                   depositor: depositor.user_key)
      end

      let(:file_set) do
        FactoryBot
          .valkyrie_create(:hyrax_file_set, edit_users: [depositor.user_key])
      end

      it "removes edit access" do
        expect { workflow_method.call(target: change_set, comment: "A pleasant read", user: user) }
          .to change { Hyrax::PermissionManager.new(resource: file_set).edit_users }
          .from(contain_exactly(depositor.user_key))
          .to be_none
      end
    end
  end
end
