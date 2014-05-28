require 'spec_helper'
require 'ostruct'

describe Worthwhile::ManagesEmbargoes do

  let(:model) {
    Class.new(ActiveFedora::Base) {

      include Worthwhile::ManagesEmbargoes

    }
  }

  let(:future_date) { 2.days.from_now }
  let(:past_date) { 2.days.ago }

  subject { model.new }

  context "[embargoes]" do
    let!(:work_with_expired_embargo1) do
      work = FactoryGirl.build(:generic_work, embargo_release_date: past_date.to_s)
      work.save(validate:false)
      work
    end
    let!(:work_with_expired_embargo2) do
      work = FactoryGirl.build(:generic_work, embargo_release_date: past_date.to_s)
      work.save(validate:false)
      work
    end
    let!(:work_with_embargo_in_effect) { FactoryGirl.create(:generic_work, embargo_release_date: future_date.to_s)}
    let!(:work_without_embargo) { FactoryGirl.create(:generic_work)}
    context "#assets_with_expired_embargoes" do
      it "returns an array of assets with expired embargoes" do
        returned_pids = subject.assets_with_expired_embargoes.map {|a| a.pid}
        expect(returned_pids).to include work_with_expired_embargo1.pid,work_with_expired_embargo2.pid
        expect(returned_pids).to_not include work_with_embargo_in_effect.pid,work_without_embargo.pid
      end
    end
    context "#assets_under_embargo" do
      it "returns all assets with embargo release date set" do
        result = subject.assets_under_embargo
        returned_pids = subject.assets_under_embargo.map {|a| a.pid}
        expect(returned_pids).to include work_with_expired_embargo1.pid,work_with_expired_embargo2.pid,work_with_embargo_in_effect.pid
        expect(returned_pids).to_not include work_without_embargo.pid
      end
    end
    context "#apply_embargo_visibility" do
      it "with one asset applies embargo visibility to the asset" do
        subject.apply_embargo_visibility( double(pid:"foo", apply_embargo_visibility!:true) )
      end
      it "with an array of assets applies embargo visibility for each asset" do
        subject.apply_embargo_visibility( [double(pid:"foo", apply_embargo_visibility!:true), double(pid:"bar", apply_embargo_visibility!:true), double(pid:"baz", apply_embargo_visibility!:true)] )
      end
    end
  end


  context "[leases]" do
    let!(:work_with_expired_lease1) do
      work = FactoryGirl.build(:generic_work, lease_expiration_date: past_date.to_s)
      work.save(validate:false)
      work
    end
    let!(:work_with_expired_lease2) do
      work = FactoryGirl.build(:generic_work, lease_expiration_date: past_date.to_s)
      work.save(validate:false)
      work
    end
    let!(:work_with_lease_in_effect) { FactoryGirl.create(:generic_work, lease_expiration_date: future_date.to_s)}
    let!(:work_without_lease) { FactoryGirl.create(:generic_work)}
    context "#assets_with_expired_leases" do
      it "returns an array of assets with expired embargoes" do
        returned_pids = subject.assets_with_expired_leases.map {|a| a.pid}
        expect(returned_pids).to include work_with_expired_lease1.pid,work_with_expired_lease2.pid
        expect(returned_pids).to_not include work_with_lease_in_effect.pid,work_without_lease.pid
      end
    end
    context "#assets_under_lease" do
      it "returns an array of assets with expired embargoes" do
        returned_pids = subject.assets_under_lease.map {|a| a.pid}
        expect(returned_pids).to include work_with_expired_lease1.pid,work_with_expired_lease2.pid,work_with_lease_in_effect.pid
        expect(returned_pids).to_not include work_without_lease.pid
      end
    end
    context "#apply_lease_visibility" do
      it "with one asset applies lease visibility to the asset" do
        subject.apply_lease_visibility( double(pid:"foo", apply_lease_visibility!:true) )
      end
      it "with an array of assets applies lease visibility for each asset" do
        subject.apply_lease_visibility( [double(pid:"see", apply_lease_visibility!:true),double(pid:"sally", apply_lease_visibility!:true),double(pid:"run", apply_lease_visibility!:true)] )
      end
    end
  end

end
