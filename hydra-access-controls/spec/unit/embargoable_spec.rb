require 'spec_helper'

describe Hydra::AccessControls::Embargoable do

  before do
    class TestModel < ActiveFedora::Base
      def save(returning_value = true)
        valid? && run_callbacks(:save) && !!returning_value
      end

      include Hydra::AccessControls::Embargoable
    end
  end

  after { Object.send(:remove_const, :TestModel) }

  let(:future_date) { Date.today+2 }
  let(:past_date) { Date.today-2 }
  let(:model) { TestModel.new }
  subject { model }

  describe '#embargo_indexer_class' do
    subject { model.embargo_indexer_class }
    it { is_expected.to eq Hydra::AccessControls::EmbargoIndexer }
  end

  describe '#lease_indexer_class' do
    subject { model.lease_indexer_class }
    it { is_expected.to eq Hydra::AccessControls::LeaseIndexer }
  end

  describe 'validations' do
    context "with dates" do
      subject { ModsAsset.new(lease_expiration_date: past_date, embargo_release_date: past_date) }
      it "validates embargo_release_date and lease_expiration_date" do
        expect(subject).to_not be_valid
        expect(subject.errors[:lease_expiration_date]).to eq ['Must be a future date']
        expect(subject.errors[:embargo_release_date]).to eq ['Must be a future date']
      end
    end

    context "without an embargo" do
      subject { ModsAsset.new }

      before { subject.valid? }

      it "doesn't create a new embargo" do
        expect(subject.embargo).to be_nil
      end

      it "doesn't create a new lease" do
        expect(subject.lease).to be_nil
      end
    end
  end

  context 'visibility=' do
    context "when the object is not under embargo or lease" do
      before do
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end
      it "doesn't create embargo or lease" do
        expect(subject.embargo).to be_nil
        expect(subject.lease).to be_nil
      end
    end

    context "when changing from embargo" do
      before do
        subject.embargo_release_date = future_date.to_s
      end
      it "wipes out associated embargo metadata" do
        expect(subject).to receive(:deactivate_embargo!)
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      end
    end

    context "when changing from lease" do
      before do
        subject.apply_lease(future_date.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
      end

      it "wipes out associated lease metadata and marks visibility as changed" do
        expect(subject).to receive(:deactivate_lease!)
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        expect(subject).to be_visibility_changed
      end
    end
  end

  describe '#apply_embargo' do
    it "applies appropriate embargo_visibility settings" do
      expect {
        subject.apply_embargo(future_date.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
      }.to change { subject.visibility_changed? }.from(false).to(true)
      expect(subject).to be_under_embargo
      expect(subject.visibility).to eq  Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      expect(subject.embargo_release_date).to eq future_date
      expect(subject.visibility_after_embargo).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    context "when no before/after visibility is provided" do
      it "relies on defaults" do
        subject.apply_embargo(future_date.to_s)
        expect(subject).to be_under_embargo
        expect(subject.visibility).to eq  Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        expect(subject.embargo_release_date).to eq future_date
        expect(subject.visibility_after_embargo).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      end
    end

    context "when the same embargo is applied" do
      before do
        subject.apply_embargo(future_date.to_s)
        if ActiveModel.version < Gem::Version.new('4.2.0')
          subject.embargo.send(:reset_changes)
        else
          subject.embargo.send(:clear_changes_information)
        end
      end

      it "doesn't call visibility_will_change!" do
        expect(subject).not_to receive(:visibility_will_change!)
        subject.apply_embargo(future_date.to_s)
      end
    end
  end

  context 'deactivate_embargo!' do
    before do
      subject.visibility_during_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      subject.visibility_after_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      subject.embargo_release_date = release_date
    end

    context "when the embargo is expired" do
      let(:release_date) { past_date.to_s }

      it "should remove the associated embargo information and record it in the object's embargo history" do
        subject.deactivate_embargo!
        expect(subject.embargo_release_date).to be_nil
        expect(subject.visibility_during_embargo).to be_nil
        expect(subject.visibility_after_embargo).to be_nil
        expect(subject.embargo_history.size).to eq 1
        expect(subject.embargo_history.first).to include("An expired embargo was deactivated on #{Date.today}.")
      end
    end

    context "when the embargo is active" do
      let(:release_date) { future_date.to_s }

      it "should remove the associated embargo information and record it in the object's embargo history" do
        expect {
          subject.deactivate_embargo!
        }.to change { subject.under_embargo? }.from(true).to(false).and change {
          subject.visibility_changed? }.from(false).to(true)
        expect(subject.embargo_release_date).to be_nil
        expect(subject.visibility_during_embargo).to be_nil
        expect(subject.visibility_after_embargo).to be_nil
        expect(subject.embargo_history.size).to eq 1
        expect(subject.embargo_history.first).to include("An active embargo was deactivated on #{Date.today}.")
      end
    end

    context "when there is no embargo" do
      let(:release_date) { nil }

      it "should not do anything" do
        subject.deactivate_embargo!
        expect(subject.embargo_history).to eq []
      end
    end
  end

  context 'apply_lease' do
    context "when the initial value is restricted" do
      it "applies appropriate embargo_visibility settings" do
        subject.apply_lease(future_date.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
        expect(subject).to be_active_lease
        expect(subject).to be_visibility_changed
        expect(subject.visibility).to eq  Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        expect(subject.lease_expiration_date).to eq future_date
        expect(subject.visibility_after_lease).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end

      context "when before/after visibility is not provided" do
        it "sets default values" do
          subject.apply_lease(future_date.to_s)
          expect(subject.visibility_during_lease).to eq  Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
          expect(subject.lease_expiration_date).to eq future_date
          expect(subject.visibility_after_lease).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        end
      end

      context "when the same lease is applied" do
        before do
          subject.apply_lease(future_date.to_s)
          if ActiveModel.version < Gem::Version.new('4.2.0')
            subject.lease.send(:reset_changes)
          else
            subject.lease.send(:clear_changes_information)
          end
        end

        it "doesn't call visibility_will_change!" do
          expect(subject).not_to receive(:visibility_will_change!)
          subject.apply_lease(future_date.to_s)
        end
      end
    end

    context "when the initial value is public" do
      before do
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        # reset the changed log
        subject.send(:instance_variable_set, :@visibility_will_change, false)
      end

      it "applies appropriate embargo_visibility settings" do
        expect {
          subject.apply_lease(future_date.to_s, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC, Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
        }.to change { subject.visibility_changed? }.from(false).to(true)
        expect(subject).to be_active_lease
        expect(subject.visibility).to eq  Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        expect(subject.lease_expiration_date).to eq future_date
        expect(subject.visibility_after_lease).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end
    end
  end

  context 'deactivate_lease!' do
    before do
      subject.lease_expiration_date = expiration_date
      subject.visibility_during_lease = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      subject.visibility_after_lease = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    context "when the lease is expired" do
      let(:expiration_date) { past_date.to_s }

      it "should remove the associated lease information and record it in the object's lease history" do
        expect {
          subject.deactivate_lease!
        }.to change { subject.visibility_changed? }.from(false).to(true)
        expect(subject.lease_expiration_date).to be_nil
        expect(subject.visibility_during_lease).to be_nil
        expect(subject.visibility_after_lease).to be_nil
        expect(subject.lease_history.size).to eq 1
        expect(subject.lease_history.first).to include("An expired lease was deactivated on #{Date.today}.")
      end
    end

    context "when the lease is active" do
      let(:expiration_date) { future_date.to_s }

      it "should remove the associated lease information and record it in the object's lease history" do
        expect {
          subject.deactivate_lease!
        }.to change { subject.active_lease? }.from(true).to(false)
        expect(subject.lease_expiration_date).to be_nil
        expect(subject.visibility_during_lease).to be_nil
        expect(subject.visibility_after_lease).to be_nil
        expect(subject.lease_history.size).to eq 1
        expect(subject.lease_history.first).to include("An active lease was deactivated on #{Date.today}.")
      end
    end

    context "when there is no lease" do
      let(:expiration_date) { nil }

      it "should not do anything" do
        subject.deactivate_lease!
        expect(subject.lease_history).to eq []
      end
    end
  end

  context 'under_embargo?' do
    context "when embargo date is past" do
      it "should return false" do
        subject.embargo_release_date = past_date.to_s
        expect(subject).to_not be_under_embargo
      end
    end
    context "when embargo date is in future" do
      it "should return true" do
        subject.embargo_release_date = future_date.to_s
        expect(subject).to be_under_embargo
      end
    end
  end

  context 'validate_visibility_complies_with_embargo' do
    before do
      subject.visibility_during_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      subject.visibility_after_embargo = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
    context "(embargo still in effect)" do
      it 'returns true if current visibility matches visibility_during_embargo' do
        subject.visibility = subject.visibility_during_embargo
        subject.embargo_release_date = future_date.to_s
        expect(subject.validate_visibility_complies_with_embargo).to be true
      end
      it 'records a failures in record.errors[:embargo]' do
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        subject.embargo_release_date = future_date.to_s
        expect(subject.validate_visibility_complies_with_embargo).to be false
        expect(subject.errors[:embargo].first).to eq "An embargo is in effect for this object until #{subject.embargo_release_date}.  Until that time the visibility should be #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE} but it is currently #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED}.  Call embargo_visibility! on this object to repair."
      end
    end
    context "(embargo expired)" do
      it 'returns true if current visibility matches visibility_after_embargo' do
        subject.visibility = subject.visibility_after_embargo
        subject.embargo_release_date = past_date.to_s
        expect(subject.validate_visibility_complies_with_embargo).to be true
      end
      it '(embargo expired) records a failures in record.errors[:embargo]' do
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        subject.embargo_release_date = past_date.to_s
        expect(subject.validate_visibility_complies_with_embargo).to be false
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
      it 'sets before/after visibility to defaults if none provided' do
        subject.visibility_during_embargo = nil
        subject.visibility_after_embargo = nil
        subject.embargo_release_date = future_date.to_s
        subject.embargo_visibility!
        expect(subject.visibility_during_embargo).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        expect(subject.visibility).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        expect(subject.visibility_after_embargo).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      end
    end
  end

  context 'validate_visibility_complies_with_lease' do
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
        expect(subject.validate_visibility_complies_with_lease).to be true
      end
      it 'records a failures in record.errors[:lease]' do
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        subject.lease_expiration_date = past_date.to_s
        expect(subject.validate_visibility_complies_with_lease).to be false
        expect(subject.errors[:lease].first).to eq "The lease expired on #{subject.lease_expiration_date}.  The visibility should be #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE} but it is currently #{Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC}.  Call lease_visibility! on this object to repair."
      end
    end
    context "(lease still in effect)" do
      it 'returns true if current visibility matches visibility_during_embargo' do
        subject.visibility = subject.visibility_during_lease
        subject.lease_expiration_date = future_date.to_s
        expect(subject.validate_visibility_complies_with_lease).to be true
      end
      it 'records a failures in record.errors[:lease]' do
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        subject.lease_expiration_date = future_date.to_s
        expect(subject.validate_visibility_complies_with_lease).to be false
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
      it "defaults to private if visibility_after_lease is not set" do
        subject.visibility_after_lease = nil
        subject.lease_expiration_date = past_date.to_s
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
      it 'sets before/after visibility to defaults if none provided' do
        subject.visibility_during_lease = nil
        subject.visibility_after_lease = nil
        subject.lease_expiration_date = future_date.to_s
        subject.lease_visibility!
        expect(subject.visibility_during_lease).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        expect(subject.visibility_after_lease).to eq Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end
    end
  end


  context 'persistence' do
    let(:the_date) { 2.days.from_now }

    it 'persists a date object' do
      subject.embargo_release_date = the_date
      expect(subject.embargo_release_date).to be_kind_of DateTime
    end

    it 'persists a valid string' do
      subject.embargo_release_date = the_date.to_s
      expect(subject.embargo_release_date).to be_kind_of DateTime
    end

    it 'raises an error on an empty string' do
      expect {
        subject.embargo_release_date = ''
      }.to raise_error(ArgumentError, "invalid date")
    end

    it 'does not persist an invalid string' do
      expect {
        subject.embargo_release_date = "Tim"
      }.to raise_error(ArgumentError, "invalid date")
    end
  end

end
