# frozen_string_literal: true

require 'valkyrie/specs/shared_specs'

RSpec.describe Hyrax::Lease, :frozen_time do
  subject(:lease) { described_class.new }

  it_behaves_like 'a Valkyrie::Resource' do
    let(:resource_klass) { described_class }
  end

  describe '#active' do
    subject(:lease) { FactoryBot.build(:hyrax_lease) }

    context 'when the lease is current' do
      it { is_expected.to be_active }
    end

    context 'when the lease is expired' do
      let!(:lease) { FactoryBot.build(:hyrax_lease, :expired) }

      before do
        travel_to Time.zone.now + 2.days
      end

      it { is_expected.not_to be_active }
    end
  end
end
