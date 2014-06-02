require 'spec_helper'

describe CurationConcern::Embargoable do

  let(:model) {
    Class.new(ActiveFedora::Base) {
      def save(returning_value = true)
        valid? && run_callbacks(:save) && !!returning_value
      end
      
      include Hydra::AccessControls::Permissions  # Embargoable assumes you've included this
      include CurationConcern::Embargoable  
      
    }
  }

  let(:future_date) { 2.days.from_now }
  let(:past_date) { 2.days.ago }
  let(:persistence) {
    subject.rightsMetadata
  }

  subject { model.new }

  it "should allow embargo to be set via attributes=" do
    pending
    expect(subject.under_embargo?).to be_false
    subject.attributes= {visibility:Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO, embargo_release_date:future_date, visibility_during_embargo:"private", visibility_during_embargo:"open" }
    expect(subject.under_embargo?).to be_true
  end
  context 'visibility=' do
    context "when passed a value of 'embargo'" do
      it "applies appropriate embargo_visibility settings" do
        subject.embargo_release_date = future_date.to_s
        expect(subject).to receive(:embargo_visibility!)
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO
      end
      it "raises ArgumentError if embargo_release_date is not set" do
        subject.embargo_release_date = nil
        expect{ subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_EMBARGO }.to raise_error ArgumentError
      end
    end
    context "when passed a value of 'lease'" do
      it "applies appropriate lease_visibility settings" do
        subject.lease_expiration_date = future_date.to_s
        expect(subject).to receive(:lease_visibility!)
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE
      end
      it "raises ArgumentError if lease_expiration_date is not set" do
        subject.lease_expiration_date = nil
        expect{ subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_LEASE }.to raise_error ArgumentError
      end
    end
    it "when changing from embargo, wipes out associated embargo metadata" do
      subject.embargo_release_date = future_date.to_s
      expect(subject).to receive(:deactivate_embargo!)
      subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
    it "when changing from lease, wipes out associated lease metadata" do
      subject.lease_expiration_date = future_date.to_s
      expect(subject).to receive(:deactivate_lease!)
      subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
  end

  context 'deactivate_embargo!' do
    it "should remove the associated embargo information and record it in the object's embargo history" do
      subject.embargo_release_date = past_date.to_s
      subject.visibility_during_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      subject.visibility_after_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      subject.deactivate_embargo!
      expect(subject.embargo_release_date).to be_nil
      expect(subject.visibility_during_embargo).to be_nil
      expect(subject.visibility_after_embargo).to be_nil
      expect(subject.embargo_history.last).to include("An expired embargo was deactivated on #{Date.today}.")
    end
  end

  context 'deactivate_lease!' do
    it "should remove the associated embargo information and record it in the object's embargo history" do
      subject.lease_expiration_date = past_date.to_s
      subject.visibility_during_lease = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      subject.visibility_after_lease = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      subject.deactivate_lease!
      expect(subject.lease_expiration_date).to be_nil
      expect(subject.visibility_during_lease).to be_nil
      expect(subject.visibility_after_lease).to be_nil
      expect(subject.lease_history.last).to include("An expired lease was deactivated on #{Date.today}.")
    end
  end

  context 'under_embargo?' do
    context "when embargo date is past" do
      it "should return false" do
        subject.embargo_release_date = past_date.to_s
        expect(subject.under_embargo?).to be_false
      end
    end
    context "when embargo date is in future" do
      it "should return true" do
        subject.embargo_release_date = future_date.to_s
        expect(subject.under_embargo?).to be_true
      end
    end
  end

  context 'validate_embargo' do
    before do
      subject.visibility_during_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      subject.visibility_after_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
    context "(embargo still in effect)" do
      it 'returns true if current visibility matches visibility_during_embargo' do
        subject.visibility = subject.visibility_during_embargo
        subject.embargo_release_date = future_date.to_s
        expect(subject.validate_embargo).to be_true
      end
      it 'records a failures in record.errors[:embargo]' do
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        subject.embargo_release_date = future_date.to_s
        expect(subject.validate_embargo).to be_false
        expect(subject.errors[:embargo].first).to eq "An embargo is in effect for this object until #{subject.embargo_release_date}.  Until that time the visibility should be #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE} but it is currently #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED}.  Call embargo_visibility! on this object to repair."
      end
    end
    context "(embargo expired)" do
      it 'returns true if current visibility matches visibility_after_embargo' do
        subject.visibility = subject.visibility_after_embargo
        subject.embargo_release_date = past_date.to_s
        expect(subject.validate_embargo).to be_true
      end
      it '(embargo expired) records a failures in record.errors[:embargo]' do
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        subject.embargo_release_date = past_date.to_s
        expect(subject.validate_embargo).to be_false
        expect(subject.errors[:embargo].first).to eq "The embargo expired on #{subject.embargo_release_date}.  The visibility should be #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC} but it is currently #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE}.  Call embargo_visibility! on this object to repair."
      end
    end
  end


  context 'embargo_visibility!' do
    let(:future_date) { 2.days.from_now }
    let(:past_date) { 2.days.ago }
    before do
      subject.visibility_during_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      subject.visibility_after_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
    context 'when embargo expired' do
      it 'applies visibility_after_embargo and calls after_apply_embargo' do
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        subject.embargo_release_date = past_date.to_s
        expect(subject).to receive(:deactivate_embargo!)
        subject.embargo_visibility!
        expect(subject.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      end
      it "defaults to private if visibility_after_embargo is not set" do
        subject.visibility_after_embargo = nil
        subject.embargo_release_date = past_date.to_s
        subject.embargo_visibility!
        expect(subject.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      end
    end
    context 'when embargo still in effect' do
      it 'applies visibility_during_embargo' do
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        subject.embargo_release_date = future_date.to_s
        expect(subject).to_not receive(:deactivate_embargo!)
        subject.embargo_visibility!
        expect(subject.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end
      it "defaults to private if visibility_during_embargo is not set" do
        subject.visibility_during_embargo = nil
        subject.embargo_release_date = future_date.to_s
        subject.embargo_visibility!
        expect(subject.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end
    end
  end

  context 'validate_lease' do
    let(:future_date) { 2.days.from_now }
    let(:past_date) { 2.days.ago }
    before do
      subject.visibility_during_lease = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      subject.visibility_after_lease = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end
    context "(lease expired)" do
      it 'returns true if current visibility matches visibility_after_lease' do
        subject.visibility = subject.visibility_after_lease
        subject.lease_expiration_date = past_date.to_s
        expect(subject.validate_lease).to be_true
      end
      it 'records a failures in record.errors[:lease]' do
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        subject.lease_expiration_date = past_date.to_s
        expect(subject.validate_lease).to be_false
        expect(subject.errors[:lease].first).to eq "The lease expired on #{subject.lease_expiration_date}.  The visibility should be #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE} but it is currently #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC}.  Call lease_visibility! on this object to repair."
      end
    end
    context "(lease still in effect)" do
      it 'returns true if current visibility matches visibility_during_embargo' do
        subject.visibility = subject.visibility_during_lease
        subject.lease_expiration_date = future_date.to_s
        expect(subject.validate_lease).to be_true
      end
      it 'records a failures in record.errors[:lease]' do
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        subject.lease_expiration_date = future_date.to_s
        expect(subject.validate_lease).to be_false
        expect(subject.errors[:lease].first).to eq "A lease is in effect for this object until #{subject.lease_expiration_date}.  Until that time the visibility should be #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC} but it is currently #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED}.  Call lease_visibility! on this object to repair."
      end
    end

  end


  context 'lease_visibility!' do
    before do
      subject.visibility_during_lease = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      subject.visibility_after_lease = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end
    context 'when lease expired' do
      it 'applies visibility_after_lease and calls after_apply_lease' do
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        subject.lease_expiration_date = past_date.to_s
        expect(subject).to receive(:deactivate_lease!)
        subject.lease_visibility!
        expect(subject.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end
    end
    context 'when lease still in effect' do
      it 'applies visibility_during_lease and calls after_apply_lease' do
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        subject.lease_expiration_date = future_date.to_s
        expect(subject).to_not receive(:deactivate_lease!)
        subject.lease_visibility!
        expect(subject.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      end
    end
  end


  context 'persistence' do
    let(:the_date) { 2.days.from_now }

    it 'persists a date object' do
      subject.embargo_release_date = the_date
      expect(persistence.embargo_release_date).to eq the_date.strftime("%Y-%m-%d") # rightsMetadata ds automatically converts dates to "%Y-%m-%d" format
    end

    it 'persists a valid string' do
      subject.embargo_release_date = the_date.to_s
      expect(persistence.embargo_release_date).to eq the_date.strftime("%Y-%m-%d") # rightsMetadata ds automatically converts dates to "%Y-%m-%d" format
    end

    it 'persists an empty string' do
      subject.embargo_release_date = ''
      expect {
        subject.save
      }.to_not change(persistence, :embargo_release_date)
    end

    it 'does not persist an invalid string' do
      subject.embargo_release_date = "Tim"
      expect {
        expect(subject.save).to eq(false)
      }.to_not change(persistence, :embargo_release_date)
    end
  end

end
