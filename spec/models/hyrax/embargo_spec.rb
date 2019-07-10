# frozen_string_literal: true

require 'valkyrie/specs/shared_specs'

RSpec.describe Hyrax::Embargo do
  subject(:embargo) { described_class.new }

  it_behaves_like 'a Valkyrie::Resource' do
    let(:resource_klass) { described_class }
  end

  describe '#active' do
    subject(:embargo) { described_class.new(embargo_release_date: release) }

    context 'when the embargo date is current' do
      let(:release) { Time.zone.today + 3 }

      it { is_expected.to be_active }
    end

    context 'when the embargo date is past' do
      let(:release) { Time.zone.today - 3 }

      it { is_expected.not_to be_active }
    end
  end
end
