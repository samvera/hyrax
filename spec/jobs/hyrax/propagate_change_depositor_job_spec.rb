# frozen_string_literal: true
RSpec.describe Hyrax::PropagateChangeDepositorJob do
  let(:depositor) { create(:user) }
  let!(:receiver) { create(:user) }

  context "for AF objects", :active_fedora do
    let(:file_set) { create(:file_set) }
    let!(:file) do
      create(:file_set, user: depositor)
    end
    let!(:work) do
      create(:work, title: ['Test work'], user: depositor).tap do |w|
        w.members << file
      end
    end

    it "changes the depositor of the child file sets" do
      described_class.perform_now(work.id, receiver, false)
      file.reload
      expect(file.depositor).to eq receiver.user_key
      expect(file.edit_users).to include(receiver.user_key, depositor.user_key)
    end

    context "when permissions are reset" do
      it "changes the depositor of the child file sets and clears edit users" do
        described_class.perform_now(work.id, receiver, true)
        file.reload
        expect(file.depositor).to eq receiver.user_key
        expect(file.edit_users).to contain_exactly(receiver.user_key)
      end
    end
  end

  context "for valkyrie objects" do
    let!(:work) { valkyrie_create(:hyrax_work, :with_member_file_sets, title: ['SoonToBeSomeoneElses'], depositor: depositor.user_key, edit_users: [depositor]) }

    before do
      work_acl = Hyrax::AccessControlList.new(resource: work)
      Hyrax.custom_queries.find_child_file_sets(resource: work).each do |file_set|
        Hyrax::AccessControlList.copy_permissions(source: work_acl, target: file_set)
      end
    end

    it "changes the depositor of the child file sets" do
      described_class.perform_now(work.id, receiver, false)
      file_sets = Hyrax.custom_queries.find_child_file_sets(resource: work)
      expect(file_sets.size).not_to eq 0 # A quick check to make sure our each block works

      file_sets.each do |file_set|
        expect(file_set.depositor).to eq receiver.user_key
        expect(file_set.edit_users.to_a).to include(receiver.user_key, depositor.user_key)
      end
    end

    context "when permissions are reset" do
      it "changes the depositor of the child file sets and clears edit users" do
        described_class.perform_now(work.id, receiver, true)
        file_sets = Hyrax.custom_queries.find_child_file_sets(resource: work)
        expect(file_sets.size).not_to eq 0 # A quick check to make sure our each block works

        file_sets.each do |file_set|
          expect(file_set.depositor).to eq receiver.user_key
          expect(file_set.edit_users.to_a).to contain_exactly(receiver.user_key)
        end
      end
    end
  end
end
