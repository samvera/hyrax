# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::ResourceStatus do
  subject(:status) { described_class.new(resource: resource) }
  let(:resource)   { fake_with_status.new }

  let(:fake_with_status) do
    Class.new do
      attr_reader :state

      def initialize(state = nil)
        @state = state
      end
    end
  end

  describe '.inactive?' do
    let(:resource) { fake_with_status.new(Hyrax::ResourceStatus::ACTIVE) }

    it { expect(described_class.inactive?(resource: resource)).to eq false }

    context 'when inactive' do
      let(:resource) { fake_with_status.new(Hyrax::ResourceStatus::INACTIVE) }

      it { expect(described_class.inactive?(resource: resource)).to eq true }
    end
  end

  describe '#active?' do
    it { is_expected.not_to be_active }

    context 'when active' do
      let(:resource) { fake_with_status.new(Hyrax::ResourceStatus::ACTIVE) }

      it { is_expected.to be_active }
    end

    context 'when deleted' do
      let(:resource) { fake_with_status.new(Hyrax::ResourceStatus::DELETED) }

      it { is_expected.not_to be_active }
    end

    context 'when inactive' do
      let(:resource) { fake_with_status.new(Hyrax::ResourceStatus::INACTIVE) }

      it { is_expected.not_to be_active }
    end

    context 'with a resource with no state' do
      let(:resource) { Valkyrie::Resource.new }

      it 'raises NoMethodError' do
        expect { status.active? }.to raise_error NoMethodError
      end
    end
  end

  describe '#deleted?' do
    it { is_expected.not_to be_deleted }

    context 'when active' do
      let(:resource) { fake_with_status.new(Hyrax::ResourceStatus::ACTIVE) }

      it { is_expected.not_to be_deleted }
    end

    context 'when deleted' do
      let(:resource) { fake_with_status.new(Hyrax::ResourceStatus::DELETED) }

      it { is_expected.to be_deleted }
    end

    context 'when inactive' do
      let(:resource) { fake_with_status.new(Hyrax::ResourceStatus::INACTIVE) }

      it { is_expected.not_to be_deleted }
    end

    context 'with a resource with no state' do
      let(:resource) { Valkyrie::Resource.new }

      it 'raises NoMethodError' do
        expect { status.deleted? }.to raise_error NoMethodError
      end
    end
  end

  describe '#inactive?' do
    it { is_expected.not_to be_inactive }

    context 'when active' do
      let(:resource) { fake_with_status.new(Hyrax::ResourceStatus::ACTIVE) }

      it { is_expected.not_to be_inactive }
    end

    context 'when deleted' do
      let(:resource) { fake_with_status.new(Hyrax::ResourceStatus::DELETED) }

      it { is_expected.not_to be_inactive }
    end

    context 'when inactive' do
      let(:resource) { fake_with_status.new(Hyrax::ResourceStatus::INACTIVE) }

      it { is_expected.to be_inactive }
    end

    context 'with a resource with no state' do
      let(:resource) { Valkyrie::Resource.new }

      it 'raises NoMethodError' do
        expect { status.inactive? }.to raise_error NoMethodError
      end
    end
  end
end
