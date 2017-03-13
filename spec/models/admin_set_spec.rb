require 'spec_helper'

RSpec.describe AdminSet, type: :model do
  let(:gf1) { create(:generic_work, user: user) }
  let(:gf2) { create(:generic_work, user: user) }

  let(:user) { create(:user) }

  before do
    subject.title = ['Some title']
  end

  describe "#default_set?" do
    context "with default AdminSet ID" do
      it "returns true" do
        expect(AdminSet.default_set?(described_class::DEFAULT_ID)).to be true
      end
    end

    context "with a non-default  ID" do
      it "returns false" do
        expect(AdminSet.default_set?('different-id')).to be false
      end
    end
  end

  describe "#destroy" do
    context "with member works" do
      before do
        subject.members = [gf1, gf2]
        subject.save!
        subject.destroy
      end

      it "does not delete adminset or member works" do
        expect(subject.errors.full_messages).to eq ["Administrative set cannot be deleted as it is not empty"]
        expect(AdminSet.exists?(subject.id)).to be true
        expect(GenericWork.exists?(gf1.id)).to be true
        expect(GenericWork.exists?(gf2.id)).to be true
      end
    end

    context "with no member works" do
      before do
        subject.members = []
        subject.save!
        subject.destroy
      end

      it "deletes the adminset" do
        expect(AdminSet.exists?(subject.id)).to be false
      end
    end

    context "is default adminset" do
      before do
        subject.members = []
        subject.id = described_class::DEFAULT_ID
        subject.save!
        subject.destroy
      end

      it "does not delete the adminset" do
        expect(subject.errors.full_messages).to eq ["Administrative set cannot be deleted as it is the default set"]
        expect(AdminSet.exists?(described_class::DEFAULT_ID)).to be true
      end
    end
  end
end
