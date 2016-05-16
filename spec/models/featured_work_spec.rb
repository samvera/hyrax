require 'spec_helper'

describe FeaturedWork, type: :model do
  let(:feature) { described_class.create(work_id: "99") }

  it "has a file" do
    expect(feature.work_id).to eq "99"
  end

  it "does not allow six features" do
    5.times do |n|
      expect(described_class.create(work_id: n.to_s)).to_not be_new_record
    end
    described_class.create(work_id: "6").tap do |sixth|
      expect(sixth).to be_new_record
      expect(sixth.errors.full_messages).to eq ["Limited to 5 featured works."]
    end
    expect(described_class.count).to eq 5
  end

  describe "can_create_another?" do
    subject { described_class }
    context "when none exist" do
      describe '#can_create_another?' do
        subject { super().can_create_another? }
        it { is_expected.to be true }
      end
    end
    context "when five exist" do
      before do
        5.times do |n|
          described_class.create(work_id: n.to_s)
        end
      end

      describe '#can_create_another?' do
        subject { super().can_create_another? }
        it { is_expected.to be false }
      end
    end
  end

  describe "#order" do
    subject { described_class.new(order: 5) }

    describe '#order' do
      subject { super().order }
      it { is_expected.to eq 5 }
    end
  end
end
