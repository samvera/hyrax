require 'spec_helper'

describe CurationConcerns::ResourceStatisticsSource do
  subject { described_class.new }
  describe "#open_concerns_count" do
    it "returns the number of open concerns" do
      create :private_generic_work
      expect(subject.open_concerns_count).to eq(0)
    end

    context "when I have concerns" do
      before do
        create :public_generic_work
      end
      it "returns the number of open concerns" do
        expect(subject.open_concerns_count).to eq(1)
      end
    end
  end

  describe "#authenticated_concerns_count" do
    context "when I have concerns" do
      before do
        create :authenticated_generic_work
      end
      it "returns the number of open concerns" do
        expect(subject.authenticated_concerns_count).to eq(1)
      end
    end
  end

  describe "#restricted_concerns_count" do
    context "when I have concerns" do
      before do
        create :authenticated_generic_work
        create :generic_work
        create :generic_work, read_groups: ['foo']
      end
      it "returns the number of open concerns" do
        expect(subject.restricted_concerns_count).to eq(2)
      end
    end
  end

  describe "embargoes" do
    before do
      create :embargoed_work, embargo_date: embargo_date, current_state: current_state, future_state: future_state
      create :public_generic_work
      create :authenticated_generic_work
      create :private_generic_work
    end

    describe "#active_embargo_now_authenticated_concerns_count" do
      before do
        create :embargoed_work, embargo_date: Date.yesterday.to_s, current_state: current_state, future_state: future_state
      end
      let(:embargo_date) { Date.tomorrow.to_s }
      let(:current_state) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
      let(:future_state) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      it "returns the number of embargo concerns" do
        expect(subject.active_embargo_now_authenticated_concerns_count).to eq(1)
      end
    end

    describe "#active_embargo_now_restricted_concerns_count" do
      let(:embargo_date) { Date.tomorrow.to_s }
      let(:current_state) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
      let(:future_state) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
      it "returns the number of embargo concerns" do
        expect(subject.active_embargo_now_restricted_concerns_count).to eq(1)
      end
    end

    describe "#expired_embargo_now_authenticated_concerns_count" do
      let(:embargo_date) { Date.yesterday.to_s }
      let(:current_state) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
      let(:future_state) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
      it "returns the number of embargo concerns" do
        expect(subject.expired_embargo_now_authenticated_concerns_count).to eq(1)
      end
    end

    describe "#expired_embargo_now_open_concerns_count" do
      let(:embargo_date) { Date.yesterday.to_s }
      let(:current_state) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
      let(:future_state) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      it "returns the number of embargo concerns" do
        expect(subject.expired_embargo_now_open_concerns_count).to eq(1)
      end
    end
  end

  describe "leases" do
    before do
      create :leased_work, lease_date: lease_date, current_state: current_state, future_state: future_state
      create :public_generic_work
      create :authenticated_generic_work
      create :private_generic_work
    end

    describe "#active_lease_now_authenticated_concerns_count" do
      let(:lease_date) { Date.tomorrow.to_s }
      let(:current_state) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
      let(:future_state) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
      it "returns the number of lease concerns" do
        expect(subject.active_lease_now_authenticated_concerns_count).to eq(1)
      end
    end

    describe "#active_lease_now_open_concerns_count" do
      let(:lease_date) { Date.tomorrow.to_s }
      let(:current_state) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      let(:future_state) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
      it "returns the number of lease concerns" do
        expect(subject.active_lease_now_open_concerns_count).to eq(1)
      end
    end

    describe "#expired_lease_now_authenticated_concerns_count" do
      let(:lease_date) { Date.yesterday.to_s }
      let(:current_state) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      let(:future_state) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
      it "returns the number of lease concerns" do
        expect(subject.expired_lease_now_authenticated_concerns_count).to eq(1)
      end
    end

    describe "#expired_lease_now_restricted_concerns_count" do
      let(:lease_date) { Date.yesterday.to_s }
      let(:current_state) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
      let(:future_state) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
      it "returns the number of lease concerns" do
        expect(subject.expired_lease_now_restricted_concerns_count).to eq(1)
      end
    end
  end
end
