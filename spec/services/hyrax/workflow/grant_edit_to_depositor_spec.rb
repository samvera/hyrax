# frozen_string_literal: true
require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::Workflow::GrantEditToDepositor do
  subject(:workflow_method) { described_class }
  let(:change_set) { Hyrax::ChangeSet.for(work) }
  let(:depositor) { FactoryBot.create(:user) }
  let(:user) { User.new }

  it_behaves_like 'a Hyrax workflow method'

  describe ".call" do
    subject do
      described_class.call(target: work,
                           comment: "A pleasant read",
                           user: user)
    end

    context 'with no depositor' do
      let(:work) { valkyrie_create(:hyrax_work, depositor: nil) }

      it 'does not change edit access' do
        expect { workflow_method.call(target: change_set, comment: "A pleasant read", user: user) }
          .not_to change { work.edit_users.to_a }
          .from(be_empty)
      end
    end

    context "with no additional editors" do
      let(:work) { valkyrie_create(:hyrax_work, depositor: depositor.user_key) }

      it "adds edit access" do
        expect { subject }.to change { work.edit_users.to_a }.from([]).to([depositor.user_key])
        expect(work).to be_persisted
      end
    end

    context "with an additional editor" do
      let(:editor) { create(:user) }
      let(:work) { valkyrie_create(:hyrax_work, depositor: depositor.user_key, edit_users: [editor.user_key]) }

      it "adds edit access" do
        expect { subject }.to change { work.edit_users.to_a }.from([editor.user_key]).to([editor.user_key, depositor.user_key])
        expect(work).to be_persisted
      end
    end

    context "with attached FileSets", :perform_enqueued do
      let(:work) { valkyrie_create(:hyrax_work, :with_one_file_set, depositor: depositor.user_key) }
      let(:file_set) { Hyrax.query_service.find_by(id: work.member_ids.first) }

      it "grants edit access" do
        expect(file_set.edit_users.count).to be_zero

        subject

        reloaded_file_set = Hyrax.query_service.find_by(id: work.member_ids.first)
        expect(reloaded_file_set.edit_users.count).to eq(1)
        expect(work).to be_persisted
      end
    end
  end
end
