# frozen_string_literal: true
RSpec.describe FeaturedWork, type: :model do
  let(:feature) { described_class.create(work_id: "99") }

  describe '.feature_limit' do
    subject { described_class.feature_limit }

    it { is_expected.to be_a(Integer) }
  end

  it "has a file" do
    expect(feature.work_id).to eq "99"
  end

  it "does not allow six features" do
    described_class.feature_limit.times do |n|
      expect(described_class.create(work_id: n.to_s)).not_to be_new_record
    end
    described_class.create(work_id: "6").tap do |sixth|
      expect(sixth).to be_new_record
      expect(sixth.errors.full_messages).to eq ["Limited to #{described_class.feature_limit} featured works."]
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
        described_class.feature_limit.times do |n|
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
