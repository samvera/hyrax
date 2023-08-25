# frozen_string_literal: true
RSpec.describe Hyrax::ChangeDepositorService do
  let!(:depositor) { FactoryBot.create(:user) }
  let!(:receiver) { FactoryBot.create(:user) }

  context "for Active Fedora objects", :active_fedora do
    let!(:work) do
      create(:work, title: ['Test work'], user: depositor)
    end
    let(:reset) { false }

    context "by default, when permissions are not reset" do
      it "changes the depositor and records an original depositor" do
        described_class.call(work, receiver, reset)
        work.reload
        expect(work.depositor).to eq receiver.user_key
        expect(work.proxy_depositor).to eq depositor.user_key
        expect(work.edit_users).to include(receiver.user_key, depositor.user_key)
      end
    end

    context "when permissions are reset" do
      let(:reset) { true }

      it "excludes the depositor from the edit users" do
        described_class.call(work, receiver, reset)
        work.reload
        expect(work.depositor).to eq receiver.user_key
        expect(work.proxy_depositor).to eq depositor.user_key
        expect(work.edit_users).to contain_exactly(receiver.user_key)
      end
    end

    context "when there are filesets" do
      let!(:file) do
        create(:file_set, user: depositor)
      end
      let!(:work) do
        create(:work, title: ['Test work'], user: depositor).tap do |w|
          w.members << file
        end
      end

      it "changes the depositor of the child file sets" do
        described_class.call(work, receiver, reset)
        expect(Hyrax::PropagateChangeDepositorJob).to have_been_enqueued.with(work.id.to_s, receiver, reset)
      end
    end
  end

  context "for Valkyrie objects" do
    let!(:base_work) { FactoryBot.valkyrie_create(:hyrax_work, title: ['SoonToBeSomeoneElses'], depositor: depositor.user_key, edit_users: [depositor]) }
    let!(:work_acl) { Hyrax::AccessControlList.new(resource: base_work) }

    context "by default, when permissions are not reset" do
      it "changes the depositor and records an original depositor" do
        described_class.call(base_work, receiver, false)
        work = Hyrax.query_service.find_by(id: base_work.id)
        expect(work.depositor).to eq receiver.user_key
        expect(work.proxy_depositor).to eq depositor.user_key
        expect(work.edit_users.to_a).to include(receiver.user_key, depositor.user_key)
        expect(ChangeDepositorEventJob).to have_been_enqueued
      end
    end

    context "when permissions are reset" do
      it "changes the depositor and records an original depositor" do
        described_class.call(base_work, receiver, true)
        work = Hyrax.query_service.find_by(id: base_work.id)
        expect(work.depositor).to eq receiver.user_key
        expect(work.proxy_depositor).to eq depositor.user_key
        expect(work.edit_users.to_a).to contain_exactly(receiver.user_key)
        expect(ChangeDepositorEventJob).to have_been_enqueued
      end
    end

    context "when there are filesets" do
      let!(:base_work) { FactoryBot.valkyrie_create(:hyrax_work, :with_member_file_sets, title: ['SoonToBeSomeoneElses'], depositor: depositor.user_key, edit_users: [depositor]) }
      before do
        Hyrax.custom_queries.find_child_file_sets(resource: base_work).each do |file_set|
          Hyrax::AccessControlList.copy_permissions(source: work_acl, target: file_set)
        end
      end

      it "changes the depositor of the child file sets" do
        described_class.call(base_work, receiver, false)
        expect(Hyrax::PropagateChangeDepositorJob).to have_been_enqueued.with(base_work.id.to_s, receiver, false)
      end
    end

    context "when no user is provided" do
      it "does not update the work" do
        expect(ChangeDepositorEventJob).not_to receive(:perform_later)
        persister = double("Valkyrie Persister")
        allow(Hyrax).to receive(:persister).and_return(persister)
        allow(persister).to receive(:save)

        described_class.call(base_work, nil, false)
        expect(persister).not_to have_received(:save)
      end
    end

    context "when transfer is requested to the existing owner" do
      let!(:base_work) { valkyrie_create(:hyrax_work, :with_member_file_sets, title: ['AlreadyMine'], depositor: depositor.user_key, edit_users: [depositor]) }

      it "does not update the work" do
        expect(ChangeDepositorEventJob).not_to receive(:perform_later)
        persister = double("Valkyrie Persister")
        allow(Hyrax).to receive(:persister).and_return(persister)
        allow(persister).to receive(:save)

        described_class.call(base_work, depositor, false)
        expect(persister).not_to have_received(:save)
      end
    end
  end
end
