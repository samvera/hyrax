require 'spec_helper'

RSpec.describe Sufia::AdminSetCreateService do
  let(:admin_set) { AdminSet.new(title: ['test']) }
  let(:service) { described_class.new(admin_set, user) }
  let(:user) { create(:user) }

  describe "#create" do
    subject { service.create }

    context "when the admin_set is valid" do
      it "is successful" do
        expect do
          expect(subject).to be true
        end.to change { admin_set.persisted? }.from(false).to(true)
        expect(admin_set.read_groups).to eq ['public']
        expect(admin_set.edit_groups).to eq ['admin']
        expect(admin_set.creator).to eq [user.user_key]
      end
    end

    context "when the admin_set is invalid" do
      let(:admin_set) { AdminSet.new } # Missing title
      it { is_expected.to be false }
    end
  end
end
