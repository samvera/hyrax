require 'spec_helper'

# It includes the Sufia::FileSetBehavior module and nothing else
# So this test covers both the FileSetBehavior module and the generated FileSet model
describe FileSet, type: :model do
  let(:user) { double(user_key: 'sarah') }
  let(:transfer_to) { create(:user) }
  let(:file) { build(:file_set, id: '123abc', user: user) }

  describe "created for someone (proxy)" do
    it "assigns proxy user" do
      file.on_behalf_of = transfer_to.user_key
      expect(ContentDepositorChangeEventJob).to receive(:perform_later).once
      file.save!
    end
  end
end
