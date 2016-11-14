require 'spec_helper'

RSpec.describe CurationConcerns::Workflow::RemoveDepositorPermissions do
  let(:work) { create(:work) }
  let(:entity) { instance_double(Sipity::Entity, id: 9999, proxy_for: work) }
  let(:user) { User.new }

  describe ".call" do
    subject do
      described_class.call(entity: entity,
                           comment: "A pleasant read",
                           user: user)
    end

    it "strips edit access " do
      subject
      expect(work).to be_valid
      expect(work.edit_users).to eq []
    end
  end
end
