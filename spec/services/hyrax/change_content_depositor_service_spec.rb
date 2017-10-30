RSpec.describe Hyrax::ChangeContentDepositorService do
  let!(:depositor) { create(:user) }
  let!(:receiver) { create(:user) }
  let!(:work) do
    create_for_repository(:work_with_one_file, title: ['Test work'], user: depositor)
  end

  before do
    described_class.call(work, receiver, reset)
  end

  context "by default, when permissions are not reset" do
    let(:reset) { false }

    it "changes the depositor and records an original depositor" do
      reloaded = Hyrax::Queries.find_by(id: work.id)
      expect(reloaded.depositor).to eq receiver.user_key
      expect(reloaded.proxy_depositor).to eq depositor.user_key
      expect(reloaded.edit_users).to include(receiver.user_key, depositor.user_key)
    end

    it "changes the depositor of the child file sets" do
      reloaded = Hyrax::Queries.find_by(id: file.id)
      expect(reloaded.depositor).to eq receiver.user_key
      expect(reloaded.edit_users).to include(receiver.user_key, depositor.user_key)
    end
  end

  context "when permissions are reset" do
    let(:reset) { true }

    it "excludes the depositor from the edit users" do
      reloaded = Hyrax::Queries.find_by(id: work.id)
      expect(reloaded.depositor).to eq receiver.user_key
      expect(reloaded.proxy_depositor).to eq depositor.user_key
      expect(reloaded.edit_users).to contain_exactly(receiver.user_key)
    end

    it "changes the depositor of the child file sets" do
      reloaded = Hyrax::Queries.find_by(id: file.id)
      expect(reloaded.depositor).to eq receiver.user_key
      expect(reloaded.edit_users).to include(receiver.user_key, depositor.user_key)
    end
  end
end
