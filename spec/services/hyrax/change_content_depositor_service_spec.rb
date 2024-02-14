# frozen_string_literal: true
RSpec.describe Hyrax::ChangeContentDepositorService do
  let!(:depositor) { create(:user) }
  let!(:receiver) { create(:user) }

  it "is deprecated" do
    work = build(:work)
    expect(Deprecation).to receive(:warn).at_least(:once)
    described_class.call(work, receiver, false)
  end

  context "for Active Fedora objects", :active_fedora do
    let!(:file) do
      create(:file_set, user: depositor)
    end
    let!(:work) do
      create(:work, title: ['Test work'], user: depositor)
    end

    before do
      work.members << file
      described_class.call(work, receiver, reset)
    end

    context "by default, when permissions are not reset" do
      let(:reset) { false }

      it "changes the depositor and records an original depositor" do
        work.reload
        expect(work.depositor).to eq receiver.user_key
        expect(work.proxy_depositor).to eq depositor.user_key
        expect(work.edit_users).to include(receiver.user_key, depositor.user_key)
      end

      it "changes the depositor of the child file sets" do
        file.reload
        expect(file.depositor).to eq receiver.user_key
        expect(file.edit_users).to include(receiver.user_key, depositor.user_key)
      end
    end

    context "when permissions are reset" do
      let(:reset) { true }

      it "excludes the depositor from the edit users" do
        work.reload
        expect(work.depositor).to eq receiver.user_key
        expect(work.proxy_depositor).to eq depositor.user_key
        expect(work.edit_users).to contain_exactly(receiver.user_key)
      end

      it "changes the depositor of the child file sets" do
        file.reload
        expect(file.depositor).to eq receiver.user_key
        expect(file.edit_users).to contain_exactly(receiver.user_key)
      end
    end
  end

  context "for Valkyrie objects" do
    let!(:base_work) { valkyrie_create(:hyrax_work, :with_member_file_sets, title: ['SoonToBeSomeoneElses'], depositor: depositor.user_key, edit_users: [depositor]) }
    before do
      work_acl = Hyrax::AccessControlList.new(resource: base_work)
      Hyrax.custom_queries.find_child_file_sets(resource: base_work).each do |file_set|
        Hyrax::AccessControlList.copy_permissions(source: work_acl, target: file_set)
      end
    end

    context "by default, when permissions are not reset" do
      it "changes the depositor and records an original depositor" do
        work = described_class.call(base_work, receiver, false)
        expect(work.depositor).to eq receiver.user_key
        expect(work.proxy_depositor).to eq depositor.user_key
        expect(work.edit_users.to_a).to include(receiver.user_key, depositor.user_key)
      end

      it "changes the depositor of the child file sets" do
        described_class.call(base_work, receiver, false)
        file_sets = Hyrax.custom_queries.find_child_file_sets(resource: base_work)
        expect(file_sets.size).not_to eq 0 # A quick check to make sure our each block works

        file_sets.each do |file_set|
          expect(file_set.depositor).to eq receiver.user_key
          expect(file_set.edit_users.to_a).to include(receiver.user_key, depositor.user_key)
        end
      end
    end

    context "when permissions are reset" do
      it "changes the depositor and records an original depositor" do
        work = described_class.call(base_work, receiver, true)
        expect(work.depositor).to eq receiver.user_key
        expect(work.proxy_depositor).to eq depositor.user_key
        expect(work.edit_users.to_a).to contain_exactly(receiver.user_key)
      end

      it "changes the depositor of the child file sets" do
        described_class.call(base_work, receiver, true)
        file_sets = Hyrax.custom_queries.find_child_file_sets(resource: base_work)
        expect(file_sets.size).not_to eq 0 # A quick check to make sure our each block works

        file_sets.each do |file_set|
          expect(file_set.depositor).to eq receiver.user_key
          expect(file_set.edit_users.to_a).to contain_exactly(receiver.user_key)
        end
      end
    end
  end
end
