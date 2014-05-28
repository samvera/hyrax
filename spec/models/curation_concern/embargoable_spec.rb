require 'spec_helper'
require 'ostruct'

describe CurationConcern::Embargoable do 

  before do
    module MockVisibility
      def visibility
        'open'
      end
    end
  end

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
        expect(subject.errors[:embargo].first).to eq "An embargo is in effect for this object until #{subject.embargo_release_date}.  Until that time the visibility should be #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE} but it is currently #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED}.  Call apply_embargo_visibility! on this object to repair."
      end
    end
    context "(embargo expired)" do
      it 'returns true if current visibility matches visibility_after_embargo' do
        subject.visibility = subject.visibility_after_embargo
        subject.embargo_release_date = past_date.to_s
        expect(subject.validate_embargo).to be_true
      end
      it '(embargo expired) records a failures in record.errors[:embargo]' do
        subject.embargo_release_date = past_date.to_s
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        expect(subject.validate_embargo).to be_false
        expect(subject.errors[:embargo].first).to eq "The embargo expired on #{subject.embargo_release_date}.  The visibility should be #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC} but it is currently #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE}.  Call apply_embargo_visibility! on this object to repair."
      end
    end
  end


  context 'apply_embargo_visibility!' do
    let(:future_date) { 2.days.from_now }
    let(:past_date) { 2.days.ago }
    before do
      subject.visibility_during_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      subject.visibility_after_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    end
    context 'when embargo expired' do
      it 'applies visibility_after_embargo and calls after_apply_embargo' do
        subject.embargo_release_date = past_date.to_s
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        expect(subject).to receive(:after_embargo_release)
        subject.apply_embargo_visibility!
        expect(subject.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      end
    end
    context 'when embargo still in effect' do
      it 'applies visibility_during_embargo and calls after_apply_embargo' do
        subject.embargo_release_date = future_date.to_s
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        expect(subject).to_not receive(:after_embargo_release)
        subject.apply_embargo_visibility!
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
    it 'returns true if everything is up to date' do
      # In effect
      subject.visibility = subject.visibility_during_lease
      subject.lease_expiration_date = future_date.to_s
      expect(subject.validate_lease).to be_true
      # Expired
      subject.visibility = subject.visibility_after_lease
      subject.lease_expiration_date = past_date.to_s
      expect(subject.validate_lease).to be_true
    end
    it '(lease still in effect) records a failures in record.errors[:embargo]' do
      subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      subject.lease_expiration_date = future_date.to_s
      expect(subject.validate_lease).to be_false
      expect(subject.errors[:lease].first).to eq "A lease is in effect for this object until #{subject.lease_expiration_date}.  Until that time the visibility should be #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC} but it is currently #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED}.  Call apply_lease_visibility! on this object to repair."
    end
    it '(lease expired) records a failures in record.errors[:embargo]' do
      subject.lease_expiration_date = past_date.to_s
      subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      expect(subject.validate_lease).to be_false
      expect(subject.errors[:lease].first).to eq "The lease expired on #{subject.lease_expiration_date}.  The visibility should be #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE} but it is currently #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC}.  Call apply_lease_visibility! on this object to repair."
    end
  end


  context 'apply_lease_visibility!' do
    before do
      subject.visibility_during_lease = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      subject.visibility_after_lease = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end
    context 'when lease expired' do
      it 'applies visibility_after_lease and calls after_apply_lease' do
        subject.lease_expiration_date = past_date.to_s
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        expect(subject).to receive(:after_lease_expiration)
        subject.apply_lease_visibility!
        expect(subject.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end
    end
    context 'when lease still in effect' do
      it 'applies visibility_during_lease and calls after_apply_lease' do
        subject.lease_expiration_date = future_date.to_s
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        expect(subject).to_not receive(:after_lease_expiration)
        subject.apply_lease_visibility!
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
