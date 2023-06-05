# frozen_string_literal: true

RSpec.describe Hyrax::VisibilityIntention do
  subject(:intention) { described_class.new(**attributes) }
  let(:attributes)    { {} }

  describe '#embargo_params' do
    it 'is empty when no embargo is requested' do
      expect(intention.embargo_params).to be_empty
    end

    context 'when an embargo is requested with no release date' do
      let(:attributes) { { visibility: described_class::EMBARGO_REQUEST } }

      it 'raises an error' do
        expect { intention.embargo_params }.to raise_error ArgumentError
      end
    end

    context 'when an embargo is requested with a release date that is not a date' do
      let(:attributes) do
        { visibility: described_class::EMBARGO_REQUEST,
          release_date: "you can't parse this (as a date)" }
      end

      it 'raises an error' do
        expect { intention.embargo_params }.to raise_error ArgumentError
      end
    end

    context 'when an embargo is requested with valid release date' do
      let(:attributes) do
        { visibility: described_class::EMBARGO_REQUEST, release_date: date }
      end

      let(:date) { Time.zone.today }

      it 'builds private -> public embargo' do
        expect(intention.embargo_params).to eq [date, described_class::PRIVATE, described_class::PUBLIC]
      end
    end

    context 'when an embargo is requested with specific visibilities' do
      let(:attributes) do
        { visibility: described_class::EMBARGO_REQUEST,
          release_date: date,
          after: after,
          during: during }
      end

      let(:after)  { 'custom_after_embargo_visibility' }
      let(:date)   { Time.zone.today }
      let(:during) { 'custom_during_embargo_visibility' }

      it 'builds private -> public embargo' do
        expect(intention.embargo_params).to eq [date, during, after]
      end
    end
  end

  describe '#lease_params' do
    it 'is empty when no lease is requested' do
      expect(intention.lease_params).to be_empty
    end

    context 'when an lease is requested with no release date' do
      let(:attributes) { { visibility: described_class::LEASE_REQUEST } }

      it 'raises an error' do
        expect { intention.lease_params }.to raise_error ArgumentError
      end
    end

    context 'when a lease is requested with a release date that is not a date' do
      let(:attributes) do
        { visibility: described_class::LEASE_REQUEST,
          release_date: "you can't parse this (as a date)" }
      end

      it 'raises an error' do
        expect { intention.lease_params }.to raise_error ArgumentError
      end
    end

    context 'when lease embargo is requested with valid release date' do
      let(:attributes) do
        { visibility: described_class::LEASE_REQUEST, release_date: date }
      end

      let(:date) { Time.zone.today }

      it 'builds public -> private lease' do
        expect(intention.lease_params).to eq [date, described_class::PUBLIC, described_class::PRIVATE]
      end
    end

    context 'when an lease is requested with specific visibilities' do
      let(:attributes) do
        { visibility: described_class::LEASE_REQUEST,
          release_date: date,
          after: after,
          during: during }
      end

      let(:after)  { 'custom_after_lease_visibility' }
      let(:date)   { Time.zone.today }
      let(:during) { 'custom_during_lease_visibility' }

      it 'builds private -> public embargo' do
        expect(intention.lease_params).to eq [date, during, after]
      end
    end
  end

  describe '#valid_embargo?' do
    it 'is false by default' do
      expect(intention.valid_embargo?).to be_falsey
    end

    context 'when an embargo is requested with no release date' do
      let(:attributes) { { visibility: described_class::EMBARGO_REQUEST } }

      it 'is false' do
        expect(intention.valid_embargo?).to be_falsey
      end
    end

    context 'when an embargo is requested with valid release date' do
      let(:attributes) do
        { visibility: described_class::EMBARGO_REQUEST, release_date: Time.zone.now.to_s }
      end

      it 'is true' do
        expect(intention.valid_embargo?).to be_truthy
      end
    end
  end

  describe '#wants_embargo?' do
    it 'is false by default' do
      expect(intention.wants_embargo?).to be_falsey
    end

    context 'when an embargo is requested' do
      let(:attributes) { { visibility: described_class::EMBARGO_REQUEST } }

      it 'is true' do
        expect(intention.wants_embargo?).to be_truthy
      end
    end
  end

  describe '#wants_lease?' do
    it 'is false by default' do
      expect(intention.wants_lease?).to be_falsey
    end

    context 'when a lease is requested' do
      let(:attributes) { { visibility: described_class::LEASE_REQUEST } }

      it 'is true' do
        expect(intention.wants_lease?).to be_truthy
      end
    end
  end
end
