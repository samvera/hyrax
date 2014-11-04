require 'spec_helper'

describe Hydra::LeaseService do
  let(:future_date) { 2.days.from_now }
  let(:past_date) { 2.days.ago }

  let!(:work_with_expired_lease1) do
    FactoryGirl.build(:asset, lease_expiration_date: past_date.to_s).tap do |work|
      work.save(validate: false)
    end
  end

  let!(:work_with_expired_lease2) do
    FactoryGirl.build(:asset, lease_expiration_date: past_date.to_s).tap do |work|
      work.save(validate: false)
    end
  end

  let!(:work_with_lease_in_effect) { FactoryGirl.create(:asset, lease_expiration_date: future_date.to_s)}
  let!(:work_without_lease) { FactoryGirl.create(:asset)}

  describe "#assets_with_expired_leases" do
    it "returns an array of assets with expired embargoes" do
      returned_ids = subject.assets_with_expired_leases.map {|a| a.id}
      expect(returned_ids).to include work_with_expired_lease1.id, work_with_expired_lease2.id
      expect(returned_ids).to_not include work_with_lease_in_effect.id, work_without_lease.id
    end
  end

  describe "#assets_under_lease" do
    it "returns an array of assets with expired embargoes" do
      returned_ids = subject.assets_under_lease.map {|a| a.id}
      expect(returned_ids).to include work_with_expired_lease1.id, work_with_expired_lease2.id, work_with_lease_in_effect.id
      expect(returned_ids).to_not include work_without_lease.id
    end
  end
end
