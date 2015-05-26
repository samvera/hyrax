require 'spec_helper'

describe CurationConcerns::EmbargoService do
  let(:future_date) { 2.days.from_now }
  let(:past_date) { 2.days.ago }

  let!(:work_with_expired_embargo1) do
    FactoryGirl.build(:generic_work, embargo_release_date: past_date.to_s).tap do |work|
      work.save(validate:false)
    end
  end

  let!(:work_with_expired_embargo2) do
    FactoryGirl.build(:generic_work, embargo_release_date: past_date.to_s).tap do |work|
      work.save(validate:false)
    end
  end

  let!(:work_with_embargo_in_effect) { FactoryGirl.create(:generic_work, embargo_release_date: future_date.to_s)}
  let!(:work_without_embargo) { FactoryGirl.create(:generic_work)}

  describe "#assets_with_expired_embargoes" do
    it "returns an array of assets with expired embargoes" do
      returned_pids = subject.assets_with_expired_embargoes.map {|a| a.id}
      expect(returned_pids).to include work_with_expired_embargo1.id,work_with_expired_embargo2.id
      expect(returned_pids).to_not include work_with_embargo_in_effect.id,work_without_embargo.id
    end
  end

  describe "#assets_under_embargo" do
    it "returns all assets with embargo release date set" do
      result = subject.assets_under_embargo
      returned_pids = subject.assets_under_embargo.map {|a| a.id}
      expect(returned_pids).to include work_with_expired_embargo1.id,work_with_expired_embargo2.id,work_with_embargo_in_effect.id
      expect(returned_pids).to_not include work_without_embargo.id
    end
  end
end
